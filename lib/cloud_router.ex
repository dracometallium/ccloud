defmodule Cloud.Router do
  def init(req, state) do
    IO.puts("\nconnection")

    case :cowboy_req.headers(req)["upgrade"] do
      "websocket" ->
        state = Map.put(state, :pending, %{})
        {:cowboy_websocket, req, state}

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

    resp = send_badreq(%{result: %{error: "Only websockets
            are supported"}})
    body = Poison.encode!(resp) <> "\n"

    req1 = :cowboy_req.reply(400, headers, body, req)
    {:ok, req1, state}
  end

  def websocket_handle({:text, body}, state) do
    try do
      req_json = Poison.decode!(body, keys: :atoms!)

      IO.puts("\nWS JSON:")
      IO.inspect(req_json)

      {state, resp} =
        cond do
          req_json[:method] == "hello_cloud" ->
            # call hello_cloud!
            hello_cloud(state, req_json)

          req_json[:method] == "connect" ->
            connection = SysUsers.get_connection(req_json.token)

            if connection != nil do
              connect(state, req_json)
            else
              {state, %{resp: "403 Forbidden", result: %{}}}
            end

          req_json[:method] == "copy_data" ->
            # do copy_data
            {state, send_badreq()}

          state.pending[req_json[:id]] != nil ->
            # Esta respondiendo a una llamada
            pending(state, req_json)

          true ->
            {state, send_badreq()}
        end

      if resp == nil do
        {:ok, state}
      else
        body = Poison.encode!(resp) <> "\n"
        {[{:text, body}], state}
      end
    rescue
      reason ->
        IO.puts("\nERROR\nbody:")
        IO.inspect(body)
        IO.puts("\nreason:")
        IO.inspect(reason)
        resp = send_badreq(%{result: %{error: reason.message}, id: nil})
        body = Poison.encode!(resp) <> "\n"
        {[{:text, body}], state}
    end
  end

  def websocket_info({:to_leader, msg, from}, state) do
    pending = Map.put(state.pending, msg.id, {:to_leader, from, msg.token})
    state = Map.put(state, :pending, pending)
    msg = Map.put(msg, :token, state.token)
    msg = Poison.encode!(msg) <> "\n"
    {state, msg}
  end

  defp hello_cloud(state, req) do
    params = req.params

    call = {:hello_cloud, params.usuario, params.password}

    id = UUIDgen.uuidgen()
    pending = Map.put(state.pending, id, call)
    state = Map.put(state, :pending, pending)

    params = %{
      usuario: "cloud",
      password: nil
      # hospital: params.hospital,
      # isla: params.isla,
      # sector: params.sector,
      # sync_id_hosp: Hospital.get_sync_id(params.hospital),
      # sync_id_isla: Isla.get_sync_id(params.hospital, params.isla)
    }

    resp = %{
      version: "0.0",
      method: "hello",
      params: params,
      id: id,
      token: UUIDgen.uuidgen()
    }

    {state, resp}
  end

  defp connect(state, req) do
    params = req.params

    call = {:connect, params.hospital, params.isla, params.sector, req.token}

    id = UUIDgen.uuidgen()
    pending = Map.put(state.pending, id, call)
    state = Map.put(state, :pending, pending)

    params = %{
      usuario: "cloud",
      hospital: params.hospital,
      isla: params.isla,
      sector: params.sector
    }

    resp = %{
      version: "0.0",
      method: "connect",
      params: params,
      id: id,
      token: req.token
    }

    {state, resp}
  end

  defp pending(state, req) do
    pending = state.pending
    {state, resp} = handle_pending(pending[req.id], req, state)
    pending = Map.delete(pending, req.id)
    state = Map.put(state, :pending, pending)
    {state, resp}
  end

  defp handle_pending(
         {:hello_cloud, user, passwd},
         req,
         state
       ) do
    token =
      SysUsers.hello(
        user,
        passwd,
        self()
      )

    {state, resp} =
      if(token != nil) do
        result = SysUsers.add_lider(token)

        cond do
          result == :ok ->
            # TODO: Hacer un update
            state = Map.put(state, :token, token)
            {state, nil}

          result == :cant ->
            resp = %{resp: "403 Forbidden", result: %{}, id: req[:id]}
            {state, resp}
        end
      else
        resp = %{resp: "403 Forbidden", result: %{}, id: req[:id]}
        {state, resp}
      end

    {state, resp}
  end

  defp handle_pending(
         {:connect, _user, hospital, isla, sector, token},
         req,
         state
       ) do
    resp =
      SysUsers.connect(
        hospital,
        isla,
        sector,
        token
      )

    resp =
      if resp == :ok do
        sync_id_hospital = Hospital.get_sync_id(hospital)
        sync_id_isla = Isla.get_sync_id(hospital, isla)

        %{
          resp: "200 OK",
          result: %{
            sync_id_hospital: sync_id_hospital,
            sync_id_isla: sync_id_isla
          },
          id: req[:id]
        }
      else
        %{resp: "403 Forbidden", result: %{}, id: req[:id]}
      end

    {state, resp}
  end

  defp handle_pending({:to_leader, pid, token}, msg, state) do
    msg = Map.put(msg, :token, token)

    if(Process.alive?(pid)) do
      send(pid, {:from_leader, msg, msg.id})
    end

    {state, nil}
  end

  defp send_badreq(add \\ %{}) do
    Map.merge(%{status: "400 Bad Request", result: %{}}, add)
  end

  def terminate(_reason, _req, _state) do
    :ok
  end
end
