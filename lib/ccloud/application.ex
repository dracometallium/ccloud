defmodule CCloud.Application do
  use Application

  @moduledoc """
  Documentation for `CCloud`.
  """

  def start(_type, _args) do
    cowboy_options = [
      certfile: "/etc/letsencrypt/live/covindex.uncoma.edu.ar/cert.pem",
      keyfile: "/etc/letsencrypt/live/covindex.uncoma.edu.ar/privkey.pem",
      cacertfile: "/etc/letsencrypt/live/covindex.uncoma.edu.ar/chain.pem",
      port: 8082
    ]

    routes = [
      {"/lider", Lider.Router, %{}},
      {"/cloud", Cloud.Router, %{}},
      {:_, NotFound.Router, %{}}
    ]

    dispatch = :cowboy_router.compile([{:_, routes}])
    cowboy_env = %{dispatch: dispatch}

    IO.inspect(
      :cowboy.start_tls(:http_listener, cowboy_options, %{env: cowboy_env})
    )

    children = [
      # Starts a worker by calling: SimpleServer.Worker.start_link(arg)
      Supervisor.child_spec(
        {CCloud.Repo, []},
        id: {CCloud.Repo, CCloud.Repo}
      ),
      Supervisor.child_spec(
        {Hospitales, []},
        id: {Hospitales, Hosplitales}
      ),
      Supervisor.child_spec(
        {Hospitales.Supervisor, []},
        id: {Hospitales.Supervisor, Hosplitales.Supervisor}
      ),
      Supervisor.child_spec(
        {Hospital.Supervisor, []},
        id: {Hospital.Supervisor, Hosplital.Supervisor}
      ),
      Supervisor.child_spec(
        {SysUsers, []},
        id: {SysUsers, SysUsers}
      )
    ]

    opts = [strategy: :one_for_one, name: Application.Supervisor]

    result = Supervisor.start_link(children, opts)
    Hospitales.Supervisor.load()
    result
  end
end
