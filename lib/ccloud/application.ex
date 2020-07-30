defmodule CCloud.Application do
  use Application

  @moduledoc """
  Documentation for `CCloud`.
  """

  def start(_type, _args) do
    cowboy_options = [
      # keyfile: "priv/keys/localhost.key",
      # certfile: "priv/keys/localhost.crt",
      # otp_app: :simple_server,
      port: 8080
    ]

    routes = [
      {"/lider", Isla.Router, []},
      {:_, NotFound.Router, []}
    ]

    dispatch = :cowboy_router.compile([{:_, routes}])
    cowboy_env = %{dispatch: dispatch}

    :cowboy.start_clear(:http_listener, cowboy_options, %{env: cowboy_env})

    children = [
      # Starts a worker by calling: SimpleServer.Worker.start_link(arg)
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

    Supervisor.start_link(children, opts)
  end
end
