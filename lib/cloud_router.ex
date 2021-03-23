defmodule Cloud.Router do
  @tick_timeout 30
  def init(req, state) do
    IO.puts("\nCloud connection")
    IO.inspect(state)

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

    IO.puts("HTTP connection: We don't want your kind here.")
    resp = send_badreq(%{result: %{error: "Only websockets are supported"}})
    body = Poison.encode!(resp)

    req1 = :cowboy_req.reply(400, headers, body, req)
    {:ok, req1, state}
  end

  def websocket_handle({:text, body}, state) do
    IO.puts("CLOUD WS JSON:")
    IO.inspect(body)
    IO.inspect(state)

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
            resp = %{
              resp: "200 OK",
              result: %{resp: "aca va la respuesta de copy_dat"},
              id: req[:id]
            }

            {state, resp}

          state.pending[req[:id]] != nil ->
            # Esta respondiendo a una llamada
            IO.puts("pending?")
            pending(state, req)

          true ->
            {state, send_badreq()}
        end

      if resp == nil do
        IO.puts("no resp, but OK")
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

        IO.puts("to leader:")
        IO.inspect(send)

        {:reply, send, state}
      end
    rescue
      reason ->
        IO.puts("Cloud ERROR\nbody:")
        IO.inspect(body)
        IO.puts("Cloud reason:")
        IO.inspect(reason)
        IO.puts(Exception.format_stacktrace())
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

  def websocket_info({:ping}, state) do
    id = UUIDgen.uuidgen()

    state = add_pending({:ping, id}, id, state)

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

  def websocket_info({:copy_data, type, data}, state) do
    id = UUIDgen.uuidgen()

    msg = %{
      version: "0.0",
      method: "copy_data",
      id: id,
      params: %{tipo: type, dato: data, triage: nil, nHC: nil},
      token: state.token
    }

    msg = Poison.encode!(msg)
    self() |> IO.inspect(label: "Cloud copy_data")
    {:reply, [{:text, msg}], state}
  end

  def websocket_info(msg, state) do
    IO.puts("Cloud websocket_info:")
    IO.inspect(msg)
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

    resp =
      SysUsers.connect(
        params[:hospital],
        params[:isla],
        params[:sector],
        req.token
      )

    {state, resp} =
      if resp == :ok do
        pid = self()
        spawn(fn -> tick(req.token, pid) end)
        sync_id_hospital = Hospital.get_sync_id(params.hospital)
        sync_id_isla = Isla.get_sync_id(params.hospital, params.isla)

        data_isla =
          if params[:sync_id_isla] != nil do
            Isla.get_update(
              params.hospital,
              params.isla,
              params.sync_id_isla
            )
          else
            %{}
          end

        data_hospital =
          if params[:sync_id_hospital] != nil do
            Hospital.get_update(
              params.hospital,
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

  defp handle_pending({:ping, id}, msg, state) do
    if msg[:result][:pong] == id do
      {state, nil}
    else
      {state, :stop}
    end
  end

  defp handle_pending({:copy_data}, _msg, state) do
    {state, nil}
  end

  defp send_badreq(add \\ %{}) do
    Map.merge(%{status: "400 Bad Request", result: %{}}, add)
  end

  def terminate(reason, _req, state) do
    IO.puts("Cloud connection termintated")
    IO.inspect(reason)
    IO.inspect(state)
    :ok
  end

  defp tick(token, pid) do
    :timer.sleep(@tick_timeout * 1000)
    send(pid, {:ping})
    tick(token, pid)
  end
end
