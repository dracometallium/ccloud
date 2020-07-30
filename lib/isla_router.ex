defmodule Isla.Router do
  def init(req, state) do
    case :cowboy_req.headers(req)["upgrade"] do
      "websocket" -> {:cowboy_websocket, req, state}
      nil -> http_handle(req, state)
      _ -> {:stop, req, state}
    end
  end

  defp http_handle(req, state) do
    {:ok, req_body, req0} = :cowboy_req.read_body(req)

    try do
      req_json = Poison.decode!(req_body, keys: :atoms!)

      %{
        :version => version,
        :method => method,
        :params => params,
        :id => id,
        :token => token
      } = req_json

      resp = connect_and_run_method(version, method, params, id, token)
      headers = %{"content-type" => "application/json"}
      body = Poison.encode!(resp) <> "\n"

      req1 = :cowboy_req.reply(200, headers, body, req0)

      {:ok, req1, state}
    rescue
      reason ->
        IO.puts("\nERROR:")
        IO.inspect(reason)
        resp = send_badreq()
        body = Poison.encode!(resp) <> "\n"
        headers = %{"content-type" => "application/json"}
        req1 = :cowboy_req.reply(400, headers, body, req0)
        {:ok, req1, state}
    end
  end

  def websocket_handle({:text, body}, state) do
    try do
      req_json = Poison.decode!(body, keys: :atoms!)

      %{
        :version => version,
        :method => method,
        :params => params,
        :id => id,
        :token => token
      } = req_json

      resp = connect_and_run_method(version, method, params, id, token)
      body = Poison.encode!(resp) <> "\n"

      {[{:text, body}], state}
    rescue
      reason ->
        IO.inspect(reason)
        body = send_badreq()
        {[{:text, body}], state}
    end
  end

  defp connect_and_run_method(version, method, params, id, token) do
    resp =
      case method do
        "hello" ->
          run_method(version, method, params, nil)

        _ ->
          connection = SysUsers.get_connection(token)

          if connection != nil do
            run_method(version, method, params, connection)
          else
            %{resp: "403 Forbidden", result: %{}}
          end
      end

    Map.put(resp, :id, id)
  end

  defp run_method("0.0", "hello", params, _connection) do
    token =
      SysUsers.hello(
        params[:user],
        params[:password],
        params[:hospital],
        params[:isla],
        params[:sector]
      )

    if token != nil do
      %{resp: "200 OK", result: %{token: token}}
    else
      %{resp: "403 Forbidden", result: %{}}
    end
  end

  defp run_method("0.0", "new_control_enfermeria", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    {sync_id, triage} = Isla.new_control_enfermeria(connection.hospital, connection.isla, data)
    %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}}
  end

  defp run_method("0.0", "get_controles_enfermerias", params, connection) do
    data = Isla.get_controles_enfermeria(connection.hospital, connection.isla, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_laboratorio", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    {sync_id, triage} = Isla.new_laboratorio(connection.hospital, connection.isla, data)
    %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}}
  end

  defp run_method("0.0", "get_laboratorios", params, connection) do
    data = Isla.get_laboratorios(connection.hospital, connection.isla, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_rx_torax", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    {sync_id, triage} = Isla.new_rx_torax(connection.hospital, connection.isla, data)
    %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}}
  end

  defp run_method("0.0", "get_rx_toraxs", params, connection) do
    data = Isla.get_rx_toraxs(connection.hospital, connection.isla, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_alerta", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    {sync_id, triage} = Isla.new_alerta(connection.hospital, connection.isla, data)
    %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}}
  end

  defp run_method("0.0", "get_alertas", params, connection) do
    data = Isla.get_alertas(connection.hospital, connection.isla, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_episodio", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    {sync_id, triage} = Isla.new_episodio(connection.hospital, connection.isla, data)
    %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}}
  end

  defp run_method("0.0", "get_episodios", params, connection) do
    data = Isla.get_episodios(connection.hospital, connection.isla, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_cama", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    sync_id = Hospital.new_cama(connection.hospital, data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_camas", params, connection) do
    data = Hospital.get_camas(connection.hospital, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_hcpasiente", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    sync_id = Hospital.new_hcpasiente(connection.hospital, data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_hcpasientes", params, connection) do
    data = Hospital.get_hcpasientes(connection.hospital, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_isla", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    sync_id = Hospital.new_isla(connection.hospital, data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_islas", params, connection) do
    data = Hospital.get_islas(connection.hospital, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_sector", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    sync_id = Hospital.new_sector(connection.hospital, data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_sectores", params, connection) do
    data = Hospital.get_sectores(connection.hospital, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_usuario_hospital", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    sync_id = Hospital.new_usuario_hospital(connection.hospital, data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_usuarios_hospital", params, connection) do
    data = Hospital.get_usuarios_hospital(connection.hospital, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_usuario_sector", params, connection) do
    data = Map.put(params.data, :id_hospital, connection.hospital)
    sync_id = Hospital.new_usuario_sector(connection.hospital, data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_usuarios_sector", params, connection) do
    data = Hospital.get_usuarios_sector(connection.hospital, params.sync_id)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "get_hospital", _params, connection) do
    data = Hospital.get_hospital(connection.hospital)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_hospital", params, _connection) do
    sync_id = Hospitales.new_hospital(params.data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "new_usuario", params, _connection) do
    usuario = Hospitales.new_usuario(params.data)
    %{status: "200 OK", result: %{usuario: usuario}}
  end

  defp run_method("0.0", "get_usuarios", _params, _connection) do
    sync_id = Hospitales.get_usuarios()
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_update", params, connection) do
    data_isla = Isla.get_update(connection.hospital, connection.isla, params.sync_id_isla)
    data_hospital = Hospital.get_update(connection.hospital, params.sync_id_hospital)
    data = Map.merge(data_isla, data_hospital)
    %{status: "200 OK", result: data}
  end

  defp run_method("0.0", "ping", params, _connection) do
    %{status: "200 OK", result: %{pong: params.ping}}
  end

  defp send_badreq() do
    %{status: "400 Bad Request", result: %{}}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end
end
