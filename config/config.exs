import Config

config :ccloud, ecto_repos: [CCloud.Repo]

config :ccloud, CCloud.Repo,
  adapter: Ecto.Adapters.MyXQL,
  database: "COVIDMASTER",
  username: "admin",
  password: "XXX",
  hostname: "localhost"

config :logger,
  level: :debug,
  backends: [:console, {LoggerFileBackend, :file_log}]

config :logger, :file_log,
  path: "myLog.log",
  level: :debug
