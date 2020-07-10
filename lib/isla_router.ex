defmodule Isla.Router do

def init(req, state) do

  {:ok, req_body, req0} = :cowboy_req.read_body(req)

  try do

    req_json = Poison.decode!(req_body, keys: :atoms!)
    %{
      :version => version,
      :method => method,
      :params => params,
      :id => id,
      :token => _token,
    } = req_json

    resp = run_method(version, method, params, id)
    headers = %{"content-type" => "application/json"}
    body = Poison.encode!(resp) <> "\n"

    req1 = :cowboy_req.reply(200, headers, body, req0)

    {:ok, req1, state}
  rescue
    reason ->
      IO.inspect reason
      send_badreq(req0, state)
  end

end

defp run_method("0.0", "test", params, id) do
  %{resp: "OK_test", result: %{params: params}, id: id}
end

defp run_method("0.0", "new_control_enfermeria", params, id) do
  {sync_id, triage} = Isla.new_control_enfermeria("test_h", "0", params.data)
  %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}, id: id}
end

defp run_method("0.0", "get_controles_enfermerias", params, id) do
  data = Isla.get_controles_enfermeria("test_h", "0", params.sync_id)
  %{status: "200 OK", result: %{data: data}, id: id}
end

defp run_method("0.0", "new_laboratorio", params, id) do
  {sync_id, triage} = Isla.new_laboratorio("test_h", "0", params.data)
  %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}, id: id}
end

defp run_method("0.0", "get_laboratorios", params, id) do
  data = Isla.get_laboratorios("test_h", "0", params.sync_id)
  %{status: "200 OK", result: %{data: data}, id: id}
end

defp run_method("0.0", "new_rx_torax", params, id) do
  {sync_id, triage} = Isla.new_rx_torax("test_h", "0", params.data)
  %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}, id: id}
end

defp run_method("0.0", "get_rx_toraxs", params, id) do
  data = Isla.get_rx_toraxs("test_h", "0", params.sync_id)
  %{status: "200 OK", result: %{data: data}, id: id}
end

defp run_method("0.0", "new_alerta", params, id) do
  {sync_id, triage} = Isla.new_alerta("test_h", "0", params.data)
  %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}, id: id}
end

defp run_method("0.0", "get_alertas", params, id) do
  data = Isla.get_alertas("test_h", "0", params.sync_id)
  %{status: "200 OK", result: %{data: data}, id: id}
end

defp run_method("0.0", "new_episodio", params, id) do
  {sync_id, triage} = Isla.new_episodio("test_h", "0", params.data)
  %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}, id: id}
end

defp run_method("0.0", "get_episodios", params, id) do
  data = Isla.get_episodios("test_h", "0", params.sync_id)
  %{status: "200 OK", result: %{data: data}, id: id}
end

defp run_method("0.0", "new_hcpasiente", params, id) do
  {sync_id, triage} = Isla.new_hcpasiente("test_h", "0", params.data)
  %{status: "200 OK", result: %{sync_id: sync_id, triage: triage}, id: id}
end

defp run_method("0.0", "get_hcpasientes", params, id) do
  data = Isla.get_hcpasientes("test_h", "0", params.sync_id)
  %{status: "200 OK", result: %{data: data}, id: id}
end

defp run_method("0.0", "get_update", params, id) do
  data = Isla.get_update("test_h", "0", params.sync_id)
  %{status: "200 OK", result: data, id: id}
end

defp run_method("0.0", "ping", params, id) do
  %{status: "200 OK", result: %{pong: params.ping}, id: id}
end

defp send_badreq(req, state) do
  headers = %{"content-type" => "application/json"}
  body = '{"status":"400 Bad Request","result":{}}\n'
  req0 = :cowboy_req.reply(400, headers, body, req)
  {:ok, req0, state}
end

def terminate(_reason, _req, _state) do
  :ok
end

end
