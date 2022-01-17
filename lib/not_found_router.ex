defmodule NotFound.Router do
  require Logger

  def init(req, state) do
    headers = %{"content-type" => "text/plain"}
    body = "404. Content Not Found."

    resp = :cowboy_req.reply(404, headers, body, req)
    Logger.info(["Connection to invalid endpoint:", inspect(req)])
    {:ok, resp, state}
  end
end
