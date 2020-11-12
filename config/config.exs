import Config

config :ccloud, ecto_repos: [CCloud.Repo]

config :ccloud, CCloud.Repo,
  adapter: Ecto.Adapters.MyXQL,
  database: "COVIDMASTER",
  username: "admin",
  password: "XXX",
  hostname: "localhost"
