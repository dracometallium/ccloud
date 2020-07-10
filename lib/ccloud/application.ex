defmodule CCloud.Application do

use Application

@moduledoc """
Documentation for `CCloud`.
"""

def start(_type, _args) do
  cowboy_options = [
    #keyfile: "priv/keys/localhost.key",
    #certfile: "priv/keys/localhost.crt",
    #otp_app: :simple_server,
    port: 8080
  ]

  routes = [
    {"/", Isla.Router, []},
    {"/ccloud/api", Isla.Router, []},
    {:_, NotFound.Router, []},
  ]
  dispatch = :cowboy_router.compile([{:_, routes}])
  cowboy_env = %{dispatch: dispatch}

  :cowboy.start_clear(:http_listener, cowboy_options, %{env: cowboy_env})

  children = [
    # Starts a worker by calling: SimpleServer.Worker.start_link(arg)
    #Plug.Adapters.Cowboy.child_spec(scheme: :http,
      #plug: Isla.Router,
      #options: cowboy_options),
    Supervisor.child_spec(
      {SyncVar, [name: :syncid_app, val: 0]},
      id: {SyncVar, :syncid_app}
    ),
    Supervisor.child_spec(
      {SyncVar, [name: :syncid_hosp, val: 0]},
      id: {SyncVar, :syncid_hosp}
    ),
    Supervisor.child_spec(
      {Isla, [id_isla: "0", id_hospital: "test_h"]},
      id: {Isla, Isla.get_atom("0","test_h")}
    ),
    ]

  opts = [ strategy: :one_for_one, name: Application.Supervisor ]

  Supervisor.start_link(children, opts)
end

end
