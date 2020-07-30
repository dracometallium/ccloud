defmodule NotFound.Router do
  def init(req, state) do
    headers = %{"content-type" => "text/plain"}
    body = "404. Content Not Found."

    resp = :cowboy_req.reply(404, headers, body, req)
    IO.inspect(resp)
    {:ok, resp, state}
  end
end
