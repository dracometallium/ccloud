defmodule Cloud.Router do
  @tick_timeout 30
  require Logger

  def init(req, state) do
    Logger.debug(["New connection to ", Atom.to_string(__MODULE__)])

    case :cowboy_req.headers(req)["upgrade"] do
      "websocket" ->
        state = Map.merge(%{pending: %{}}, state)

        opts = %{
          :idle_timeout => 600_000
        }

        {:cowboy_websocket, req, state, opts}

      nil ->
        http_handle(req, state)

      _ ->
        {:stop, req, state}
    end
  end

  defp http_handle(req, state) do
    headers = %{
      "Access-Control-Allow-Headers" =>
        "token, Authorization, X-API-KEY, Origin, X-Requested-with, Content-Type, Accept, Access-Control-Allow-Request-Method",
      "Access-Control-Allow-Methods" =>
        "GET, HEAD, POST, OPTIONS, PUT, DELETE",
      "Access-Control-Allow-Origin" => "*",
      "Allow" => "GET, HEAD, POST, OPTIONS, PUT, DELETE",
      "content-type" => "application/json"
    }

    Logger.info("HTTP connection: We don't want your kind here.")
    resp = send_badreq(%{result: %{error: "Only websockets are supported"}})
    body = Poison.encode!(resp)

    req1 = :cowboy_req.reply(400, headers, body, req)
    {:ok, req1, state}
  end

  def websocket_handle({:text, body}, state) do
    Logger.debug([Atom.to_string(__MODULE__), " WS body:\n", body])

    try do
      req = Poison.decode!(body, keys: :atoms)

      {state, resp} =
        cond do
          req[:method] == "hello" ->
            hello_cloud(state, req)

          req[:method] == "connect" ->
            connection = SysUsers.get_connection(req[:token])

            if connection != nil do
              connect(state, req)
            else
              {state,
               %{
                 resp: "403 Forbidden",
                 result: %{error: "Did you make a `hello`?"},
                 id: req[:id]
               }}
            end

          req[:method] == "copy_data" ->
            connection = SysUsers.get_connection(req[:token])

            resp =
              if connection != nil do
                if connection.ready do
                  copy_data(req[:version], req.params.tipo, req, connection)
                else
                  %{
                    resp: "403 Forbidden",
                    result: %{error: "you need to connect first!"}
                  }
                end
              else
                %{
                  resp: "403 Forbidden",
                  result: %{error: "Sorry, I didn't find the token."}
                }
              end

            {state, resp}

          state.pending[req[:id]] != nil ->
            # Esta respondiendo a una llamada
            pending(state, req)

          true ->
            # {state, send_badreq()}
            # We route anything else to the lider.router
            {[{:text, resp}], state} =
              Lider.Router.websocket_handle({:text, body}, state)

            resp = Poison.decode!(resp, keys: :atoms)

            {state, resp}
        end

      if resp == nil do
        Logger.debug("no resp, but OK")
        {:ok, state}
      else
        send =
          if is_list(resp) do
            Enum.map(resp, fn r ->
              {:text, Poison.encode!(r)}
            end)
          else
            [{:text, Poison.encode!(resp)}]
          end

        Logger.debug([
          Atom.to_string(__MODULE__),
          " to leader:",
          inspect(send)
        ])

        {:reply, send, state}
      end
    rescue
      reason ->
        Logger.warn([
          Atom.to_string(__MODULE__),
          " WS\n",
          body,
          "reason:\n",
          inspect(reason),
          "stack:\n",
          Exception.format_stacktrace()
        ])

        resp = send_badreq(%{result: %{error: reason}, id: nil})
        body = Poison.encode!(resp)
        {:reply, [{:text, body}], state}
    end
  end

  def websocket_info({:to_leader, msg, from}, state) do
    old_id = msg.id
    msg = Map.put(msg, :id, UUIDgen.uuidgen())
    state = add_pending({:to_leader, from, msg.token, old_id}, msg.id, state)

    msg = Map.put(msg, :token, state.token)
    msg = Poison.encode!(msg)

    {:reply, [{:text, msg}], state}
  end

  def websocket_info({:ping, from}, state) do
    id = UUIDgen.uuidgen()
    date = DateTime.utc_now() |> DateTime.to_unix()

    state = add_pending({:ping, id, date, from}, id, state)

    msg = %{
      version: "0.0",
      method: "ping",
      id: id,
      params: %{ping: id},
      token: state.token
    }

    msg = Poison.encode!(msg)
    {:reply, [{:text, msg}], state}
  end

  def websocket_info({:copy_data, type, data, triage, nhc}, state) do
    id = UUIDgen.uuidgen()

    msg = %{
      version: "0.0",
      method: "copy_data",
      id: id,
      params: %{tipo: type, dato: data, triage: triage, nHC: nhc},
      token: state.token
    }

    msg = Poison.encode!(msg)
    Logger.debug([Atom.to_string(__MODULE__), " copy_data msg: ", msg])
    {:reply, [{:text, msg}], state}
  end

  def websocket_info({:EXIT, _pid, _cause}, state) do
    {:ok, state}
  end

  def websocket_info(msg, state) do
    Logger.debug([
      Atom.to_string(__MODULE__),
      " websocket_info:",
      inspect(msg)
    ])

    {:ok, state}
  end

  defp add_pending(msg, id, state) do
    pending = Map.put(state.pending, id, msg)
    Map.put(state, :pending, pending)
  end

  defp hello_cloud(state, req) do
    params = req.params

    token =
      SysUsers.hello(
        params[:user],
        params[:password],
        self()
      )

    resp =
      if token != nil do
        datosUsuario = Hospitales.get_datos_usuario(params[:user])

        %{
          resp: "200 OK",
          result: Map.merge(datosUsuario, %{token: token}),
          id: req.id
        }
      else
        %{
          resp: "403 Forbidden",
          result: %{error: "Wrong password."},
          id: req.id
        }
      end

    {state, resp}
  end

  defp connect(state, req) do
    params = req.params

    hospital = params[:hospital]
    sector = params[:sector]
    isla = Hospital.get_isla(hospital, sector)

    resp =
      SysUsers.connect(
        hospital,
        isla,
        sector,
        req.token
      )

    {state, resp} =
      if resp == :ok do
        pid = self()
        spawn(fn -> tick(req.token, pid) end)
        sync_id_hospital = Hospital.get_sync_id(hospital)
        sync_id_isla = Isla.get_sync_id(hospital, isla)

        data_isla =
          if params[:sync_id_isla] != nil do
            Isla.get_update(
              hospital,
              isla,
              nil,
              params.sync_id_isla
            )
          else
            %{}
          end

        data_hospital =
          if params[:sync_id_hospital] != nil do
            Hospital.get_update(
              hospital,
              params.sync_id_hospital
            )
          else
            %{}
          end

        data = Map.merge(data_isla, data_hospital)

        resp = %{
          resp: "200 OK",
          result: %{
            sync_id_hospital: sync_id_hospital,
            sync_id_isla: sync_id_isla,
            update: data
          },
          method: "update_response",
          id: req.id
        }

        SysUsers.add_lider(req.token)
        state = Map.put(state, :token, req.token)

        {state, resp}
      else
        {state,
         %{
           resp: "403 Forbidden",
           result: %{error: "Error while connecting, sorry."}
         }, id: req.id}
      end

    {state, resp}
  end

  defp copy_data(ver, "signosVitales", req, connection) do
    copy_data(ver, "signo_vital", req, connection)
  end

  defp copy_data("0.0", "signo_vital", req, connection) do
    params = req.params
    data = params.dato
    triage = params[:triage]
    nhc = params[:nHC]
    isla = connection[:isla]
    hospital = connection[:hospital]

    sync_id = Isla.copy_signo_vital(hospital, isla, data)

    send_copy_data(:signo_vital, data, hospital, isla, triage, nhc)

    %{status: "200 OK", result: %{sync_id: sync_id}, id: req.id}
  end

  defp copy_data("0.0", "laboratorio", req, connection) do
    params = req.params
    data = params.dato
    triage = params[:triage]
    nhc = params[:nHC]
    isla = connection[:isla]
    hospital = connection[:hospital]

    sync_id = Isla.copy_laboratorio(hospital, isla, data)

    send_copy_data(:laboratorio, data, hospital, isla, triage, nhc)

    %{status: "200 OK", result: %{sync_id: sync_id}, id: req.id}
  end

  defp copy_data("0.0", "rx_torax", req, connection) do
    params = req.params
    data = params.dato
    triage = params[:triage]
    nhc = params[:nHC]
    isla = connection[:isla]
    hospital = connection[:hospital]

    sync_id = Isla.copy_rx_torax(hospital, isla, data)

    send_copy_data(:rx_torax, data, hospital, isla, triage, nhc)

    %{status: "200 OK", result: %{sync_id: sync_id}, id: req.id}
  end

  defp copy_data("0.0", "alerta", req, connection) do
    params = req.params
    data = params.dato
    triage = params[:triage]
    nhc = params[:nHC]
    isla = connection[:isla]
    hospital = connection[:hospital]

    sync_id = Isla.copy_alerta(hospital, isla, data)

    send_copy_data(:alerta, data, hospital, isla, triage, nhc)

    %{status: "200 OK", result: %{sync_id: sync_id}, id: req.id}
  end

  defp copy_data("0.0", "episodio", req, connection) do
    params = req.params
    data = params.dato
    triage = params[:triage]
    nhc = params[:nHC]
    isla = connection[:isla]
    hospital = connection[:hospital]

    sync_id = Isla.copy_episodio(hospital, isla, data)

    send_copy_data(:episodio, data, hospital, isla, triage, nhc)

    %{status: "200 OK", result: %{sync_id: sync_id}, id: req.id}
  end

  defp copy_data("0.0", "hcpaciente", req, connection) do
    params = req.params
    data = params.dato
    triage = params[:triage]
    nhc = params[:nHC]
    isla = connection[:isla]
    hospital = connection[:hospital]
    data = List.wrap(data)
    data = Enum.map(data,
          fn x ->
            Map.put(x, :idIsla, isla)
          end)

    sync_id = Isla.copy_hcpaciente(hospital, isla, data)

    send_copy_data(:hcpaciente, data, hospital, isla, triage, nhc)

    %{status: "200 OK", result: %{sync_id: sync_id}, id: req.id}
  end

  defp copy_data(version, type, _req, _connection) do
    send_badreq(%{
      result:
        "unkown type: '" <>
          type <>
          "' on version: " <>
          version
    })
  end

  defp pending(state, req) do
    pending = state.pending
    id = req.id
    {state, resp} = handle_pending(pending[id], req, state)
    pending = state.pending
    pending = Map.delete(pending, id)
    state = Map.put(state, :pending, pending)
    {state, resp}
  end

  defp handle_pending({:to_leader, pid, token, old_id}, msg, state) do
    msg = Map.put(msg, :token, token)
    msg = Map.put(msg, :id, old_id)

    if(Process.alive?(pid)) do
      send(pid, {:from_leader, msg, msg.id})
    end

    {state, nil}
  end

  defp handle_pending({:ping, id, date, from}, msg, state) do
    if msg[:result][:pong] == id do
      now = DateTime.utc_now() |> DateTime.to_unix()

      Logger.debug([
        Atom.to_string(__MODULE__),
        " ping: ",
        Integer.to_string(now - date)
      ])

      if from != nil do
        {id_from, pid_from} = from
        send(pid_from, {:pong, id_from})
      end

      {state, nil}
    else
      Logger.warn([Atom.to_string(__MODULE__), " WRONG PING: ", inspect(msg)])
      {state, nil}
    end
  end

  defp handle_pending({:copy_data}, _msg, state) do
    {state, nil}
  end

  defp send_copy_data(
         type,
         data,
         hospital,
         isla,
         triage \\ nil,
         nhc \\ nil
       ) do
    # Sends the new hospital data to the other clients
    spawn(fn ->
      send_copy_data_async(type, data, hospital, isla, triage, nhc)
    end)

    :ok
  end

  defp send_copy_data_async(type, data, hospital, isla, triage, nhc) do
    # Sends the new data to the other clients
    clients = SysUsers.get_clients(hospital, isla)

    Enum.each(clients, fn pid ->
      if pid != nil and Process.alive?(pid) do
        send(pid, {:copy_data, type, data, triage, nhc})
      end
    end)
  end

  defp send_badreq(add \\ %{}) do
    Map.merge(%{status: "400 Bad Request", result: %{}}, add)
  end

  def terminate(reason, _req, state) do
    Logger.debug([
      Atom.to_string(__MODULE__),
      " connection termintated: ",
      inspect(reason),
      "\nstate: ",
      inspect(state)
    ])

    :ok
  end

  defp tick(token, pid) do
    :timer.sleep(@tick_timeout * 1000)
    send(pid, {:ping, nil})
    tick(token, pid)
  end
end
