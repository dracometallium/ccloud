defmodule Lider.Router do
  require Logger

  def init(req, state) do
    Logger.debug(["New connection to ", Atom.to_string(__MODULE__)])

    case :cowboy_req.headers(req)["upgrade"] do
      "websocket" ->
        opts = %{
          :idle_timeout => 600_000
        }

        {:cowboy_websocket, req, state, opts}

      nil ->
        http_handle(req, state)

      _ ->
        {:stop, req, state}
    end
  end

  defp http_handle(req, state) do
    case :cowboy_req.method(req) do
      "OPTIONS" ->
        req0 = :cowboy_req.reply(200, headers(headers_cors()), "", req)
        {:ok, req0, state}

      _ ->
        {:ok, req_body, req0} = :cowboy_req.read_body(req)

        try do
          # Conviene usar ":atoms!" para que no se creen átomos nuevos
          req_json = Poison.decode!(req_body, keys: :atoms)

          Logger.debug([
            Atom.to_string(__MODULE__),
            " HTTP JSON:\n",
            inspect(req_json)
          ])

          %{
            :version => version,
            :method => method,
            :params => _params,
            :id => id,
            :token => token
          } = req_json

          {state, resp} =
            connect_and_run_method(
              version,
              method,
              req_json,
              id,
              token,
              state
            )

          headers = headers()

          body = Poison.encode!(resp) <> "\n"
          Logger.debug([Atom.to_string(__MODULE__), " to client:", body])

          req1 = :cowboy_req.reply(200, headers, body, req0)

          {:ok, req1, state}
        rescue
          reason ->
            Logger.warn([
              Atom.to_string(__MODULE__),
              " HTTP\n",
              req_body,
              "reason:\n",
              inspect(reason),
              "stack:\n",
              Exception.format_stacktrace()
            ])

            resp = send_badreq() |> Map.put(:result, %{error: reason})
            body = Poison.encode!(resp) <> "\n"

            headers = headers()

            req1 = :cowboy_req.reply(400, headers, body, req0)
            {:ok, req1, state}
        end
    end
  end

  defp headers(base \\ %{}) do
    Map.merge(base, %{
      "access-control-allow-origin" => "*",
      "content-type" => "application/json"
    })
  end

  defp headers_cors(base \\ %{}) do
    Map.merge(base, %{
      "access-control-allow-headers" => "content-type",
      "access-control-allow-methods" =>
        "GET, HEAD, POST, OPTIONS, PUT, DELETE",
      "access-control-allow-origin" => "*",
      "access-control-request-headers" => "content-type"
    })
  end

  def websocket_handle({:text, body}, state) do
    try do
      req_json = Poison.decode!(body, keys: :atoms!)

      %{
        :version => version,
        :method => method,
        :params => _params,
        :id => id,
        :token => token
      } = req_json

      Logger.debug([
        Atom.to_string(__MODULE__),
        " WS JSON:\n",
        inspect(req_json)
      ])

      {state, resp} =
        connect_and_run_method(version, method, req_json, id, token, state)

      body = Poison.encode!(resp) <> "\n"

      Logger.debug([Atom.to_string(__MODULE__), " to client:", body])

      {[{:text, body}], state}
    rescue
      reason ->
        Logger.warn([
          Atom.to_string(__MODULE__),
          " WS\n",
          body,
          "reason:\n",
          inspect(reason),
          "stack:\n",
          Exception.format_stacktrace()
        ])

        body = send_badreq()
        body = Poison.encode!(body) <> "\n"
        {[{:text, body}], state}
    end
  end

  defp connect_and_run_method(version, method, req, id, token, state) do
    {state, resp} =
      case method do
        "hello" ->
          resp = run_method(version, method, req, nil)
          {state, resp}

        "connect" ->
          connection = SysUsers.get_connection(token)

          if connection != nil do
            resp = run_method(version, method, req, connection)
            state = Map.put(state, :token, token)
            {state, resp}
          else
            resp = %{
              resp: "403 Forbidden",
              result: %{error: "Did you make a `hello`?"}
            }

            {state, resp}
          end

        _ ->
          connection = SysUsers.get_connection(token)

          resp =
            if connection != nil do
              if connection.ready do
                run_method(version, method, req, connection)
              else
                %{
                  resp: "403 Forbidden",
                  result: %{error: "you need to connect first!"}
                }
              end
            else
              %{
                resp: "403 Forbidden",
                result: %{error: "Sorry, I didn't find the token."}
              }
            end

          {state, resp}
      end

    resp = Map.put(resp, :id, id)
    {state, resp}
  end

  defp run_method("0.0", "hello", req, _connection) do
    params = req.params

    token =
      SysUsers.hello(
        params[:user],
        params[:password],
        self()
      )

    if token != nil do
      datosUsuario = Hospitales.get_datos_usuario(params[:user])
      %{resp: "200 OK", result: Map.merge(datosUsuario, %{token: token})}
    else
      %{resp: "403 Forbidden", result: %{error: "Wrong password."}}
    end
  end

  defp run_method("0.0", "connect", req, _connection) do
    params = req.params
    hospital = params[:hospital]
    sector = params[:sector]
    isla = Hospital.get_isla(hospital, sector)

    resp =
      SysUsers.connect(
        hospital,
        isla,
        sector,
        req.token
      )

    if resp == :ok do
      {data_isla, sync_id_isla} =
        cond do
          isla == nil ->
            {%{}, nil}

          params[:sync_id_isla] == nil ->
            sync_id_isla = Isla.get_sync_id(hospital, isla)
            {%{}, sync_id_isla}

          true ->
            sync_id_isla = Isla.get_sync_id(hospital, isla)

            data_isla =
              Isla.get_update(
                hospital,
                isla,
                sector,
                params.sync_id_isla
              )

            {data_isla, sync_id_isla}
        end

      sync_id_hospital = Hospital.get_sync_id(hospital)

      data_hospital =
        if params[:sync_id_hospital] != nil do
          Hospital.get_update(
            hospital,
            params.sync_id_hospital
          )
        else
          %{}
        end

      data = Map.merge(data_isla, data_hospital)

      %{
        resp: "200 OK",
        result: %{
          sync_id_hospital: sync_id_hospital,
          sync_id_isla: sync_id_isla,
          update: data
        }
      }
    else
      %{
        resp: "403 Forbidden",
        result: %{error: "Error while connecting, sorry."}
      }
    end
  end

  defp run_method("0.0", "new_signo_vital", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    data =
      Map.merge(req.params.data, %{
        idHospital: connection[:hospital]
      })

    params = Map.put(req.params, :data, data)
    req = Map.put(req, :params, params)

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})
      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "modify_signo_vital", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})
      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "get_signos_vitales", req, connection) do
    if_fail = fn isla ->
      Isla.get_signos_vitales(
        connection[:hospital],
        isla,
        connection[:sector],
        req.params.sync_id
      )
    end

    data = send_get_data(if_fail, req, connection)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_laboratorio", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    data =
      Map.merge(req.params.data, %{
        idHospitalLab: connection[:hospital]
      })

    params = Map.put(req.params, :data, data)
    req = Map.put(req, :params, params)

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "modify_laboratorio", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "get_laboratorios", req, connection) do
    if_fail = fn isla ->
      Isla.get_laboratorios(
        connection[:hospital],
        isla,
        connection[:sector],
        req.params.sync_id
      )
    end

    data = send_get_data(if_fail, req, connection)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_rx_torax", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    data =
      Map.merge(req.params.data, %{
        idHospitalRad: connection[:hospital]
      })

    params = Map.put(req.params, :data, data)
    req = Map.put(req, :params, params)

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "modify_rx_torax", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "get_rx_toraxs", req, connection) do
    if_fail = fn isla ->
      Isla.get_rx_toraxs(
        connection[:hospital],
        isla,
        connection[:sector],
        req.params.sync_id
      )
    end

    data = send_get_data(if_fail, req, connection)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_alerta", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    data =
      Map.merge(req.params.data, %{
        idHospital: connection[:hospital]
      })

    params = Map.put(req.params, :data, data)
    req = Map.put(req, :params, params)

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "modify_alerta", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "get_alertas", req, connection) do
    if_fail = fn isla ->
      Isla.get_alertas(
        connection[:hospital],
        isla,
        connection[:sector],
        connection.user,
        req.params.sync_id
      )
    end

    data = send_get_data(if_fail, req, connection)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_episodio", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    data =
      Map.merge(req.params.data, %{
        idHospital: connection[:hospital]
      })

    params = Map.put(req.params, :data, data)
    req = Map.put(req, :params, params)

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "modify_episodio", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "get_episodios", req, connection) do
    if_fail = fn isla ->
      Isla.get_episodios(
        connection[:hospital],
        isla,
        connection[:sector],
        req.params.sync_id
      )
    end

    data = send_get_data(if_fail, req, connection)
    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_hcpaciente", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    data =
      Map.merge(req.params.data, %{
        idHospital: connection[:hospital]
      })

    params = Map.put(req.params, :data, data)
    req = Map.put(req, :params, params)

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "modify_hcpaciente", req, connection) do
    isla =
      if connection[:isla] == nil do
        req.params.data.idIsla
      else
        connection[:isla]
      end

    pid = SysUsers.get_lider(connection[:hospital], isla)

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "get_hcpacientes", req, connection) do
    if_fail = fn isla ->
      Isla.get_hcpacientes(
        connection[:hospital],
        isla,
        # connection[:sector],
        nil,
        req.params.sync_id
      )
    end

    data = send_get_data(if_fail, req, connection)
    %{status: "200 OK", result: %{data: data}}
  end

  # Dependen del hospital

  defp run_method("0.0", "new_cama", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospitalCama, connection[:hospital])
    sync_id = Hospital.new_cama(connection[:hospital], data)

    send_copy_data(:cama, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "modify_cama", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospitalCama, connection[:hospital])
    sync_id = Hospital.modify_cama(connection[:hospital], data)

    send_copy_data(:cama, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_camas", req, connection) do
    params = req.params

    data =
      Hospital.get_camas(connection[:hospital], params.sync_id)
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_isla", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    IO.inspect(data)
    sync_id = Hospital.new_isla(connection[:hospital], data)

    send_copy_data(:isla, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "modify_isla", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    IO.inspect(data)
    sync_id = Hospital.modify_isla(connection[:hospital], data)

    send_copy_data(:isla, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_islas", req, connection) do
    params = req.params

    data =
      Hospital.get_islas(connection[:hospital], params.sync_id)
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_sector", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    sync_id = Hospital.new_sector(connection[:hospital], data)

    send_copy_data(:sector, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "modify_sector", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    sync_id = Hospital.modify_sector(connection[:hospital], data)

    send_copy_data(:sector, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_sectores", req, connection) do
    params = req.params

    data =
      Hospital.get_sectores(connection[:hospital], params.sync_id)
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "get_datos_usuario", req, _connection) do
    params = req.params

    data =
      Hospital.get_datos_usuario(params.hospital, params.cuil)
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_usuario_hospital", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    sync_id = Hospital.new_usuario_hospital(connection[:hospital], data)

    send_copy_data(
      :usuario_hospital,
      data,
      connection[:hospital],
      nil
    )

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "modify_usuario_hospital", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    sync_id = Hospital.modify_usuario_hospital(connection[:hospital], data)

    send_copy_data(
      :usuario_hospital,
      data,
      connection[:hospital],
      nil
    )

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_usuarios_hospital", req, connection) do
    params = req.params

    data =
      Hospital.get_usuarios_hospital(connection[:hospital], params.sync_id)
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_usuario_sector", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    sync_id = Hospital.new_usuario_sector(connection[:hospital], data)

    send_copy_data(:usuario_sector, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "modify_usuario_sector", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHospital, connection[:hospital])
    sync_id = Hospital.modify_usuario_sector(connection[:hospital], data)

    send_copy_data(:usuario_sector, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_usuarios_sector", req, connection) do
    params = req.params

    data =
      Hospital.get_usuarios_sector(connection[:hospital], params.sync_id)
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_hospital", req, _connection) do
    params = req.params
    sync_id = Hospitales.new_hospital(params.data)
    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "modify_hospital", req, connection) do
    params = req.params
    data = Map.put(params.data, :idHosp, connection[:hospital])
    sync_id = Hospital.modify_usuario_sector(connection[:hospital], data)

    send_copy_data(:usuario_sector, data, connection[:hospital], nil)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_hospital", _req, connection) do
    data =
      Hospital.get_hospital(connection[:hospital])
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{data: data}}
  end

  defp run_method("0.0", "new_usuario", req, _connection) do
    params = req.params
    data = Hospitales.new_usuario(params.data)

    %{status: "200 OK", result: %{usuario: data}}
  end

  defp run_method("0.0", "get_usuarios", _req, _connection) do
    sync_id =
      Hospitales.get_usuarios()
      |> Enum.map(fn x -> Map.put(x, :actual, 1) end)

    %{status: "200 OK", result: %{sync_id: sync_id}}
  end

  defp run_method("0.0", "get_update", req, connection) do
    params = req.params

    pid = SysUsers.get_lider(connection[:hospital], connection[:isla])

    if pid != nil do
      send(pid, {:to_leader, req, self()})

      id = req.id

      receive do
        {:from_leader, resp, ^id} ->
          resp =
            if(resp.resp == "200 OK") do
              data_hospital =
                Hospital.get_update(
                  connection[:hospital],
                  params.sync_id_hospital
                )

              # TODO: guardar datos del lider.
              data = Map.merge(resp.result, data_hospital)
              resp = Map.put(resp, :result, data)
              resp
            else
              resp
            end

          resp
      after
        10000 ->
          send_noleader(%{})
      end
    else
      send_noleader(%{result: %{error: "Leader not connected"}})
    end
  end

  defp run_method("0.0", "alerta_vista", req, connection) do
    params = req.params

    result =
      Isla.new_alerta_vista(
        connection.hospital,
        params.data.numeroHC,
        params.data.fechaAlerta,
        connection.user
      )

    case result do
      :ok -> %{status: "200 OK"}
      {:error, reason} -> send_badreq(%{result: %{error: reason}})
    end
  end

  defp run_method("0.0", "ping", req, _connection) do
    params = req.params
    %{status: "200 OK", result: %{pong: params.ping}}
  end

  defp run_method("0.0", "get_provincias", _req, _connection) do
    provincias = Pais.get_provincias("ar")
    %{status: "200 OK", result: %{provincias: provincias}}
  end

  defp run_method("0.0", "get_localidades", req, _connection) do
    params = req.params
    localidades = Pais.get_localidades("ar", params.id_provincia)
    %{status: "200 OK", result: %{localidades: localidades}}
  end

  defp run_method(version, method, _req, _connection) do
    send_badreq(%{
      result:
        "unkown method: '" <>
          method <>
          "' on version: " <>
          version
    })
  end

  defp send_badreq(add \\ %{}) do
    Map.merge(%{status: "400 Bad Request", result: %{}}, add)
  end

  defp send_noleader(add) do
    Map.merge(%{status: "503 Service Unavailable", result: %{}}, add)
  end

  defp send_get_data(fun_if_fail, _req, connection) do
    hospital = connection[:hospital]

    islas =
      if connection[:isla] == nil do
        Hospital.get_islas(hospital, 0)
        |> Enum.map(fn isla -> isla.idIsla end)
      else
        [connection[:isla]]
      end

    current = self()
    id = make_ref()

    Enum.each(islas, fn isla ->
      spawn(fn ->
        lider_status = SysUsers.ping_lider(hospital, isla)
        send(current, {id, isla, lider_status})
      end)
    end)

    islas =
      Enum.map(islas, fn isla ->
        receive do
          {^id, ^isla, lider_status} -> {isla, lider_status}
        end
      end)

    data =
      Enum.reduce(islas, [], fn {isla, lider_status}, acc ->
        data =
          if lider_status == :ok do
            fun_if_fail.(isla) |> Enum.map(fn x -> Map.put(x, :actual, 1) end)
          else
            fun_if_fail.(isla) |> Enum.map(fn x -> Map.put(x, :actual, 0) end)
          end

        [data | acc]
      end)

    Enum.concat(data)
  end

  defp send_copy_data(
         type,
         data,
         hospital,
         isla,
         triage \\ nil,
         nhc \\ nil
       ) do
    # Sends the new hospital data to the other clients
    from = self()

    spawn(fn ->
      send_copy_data_async(
        from,
        type,
        data,
        hospital,
        isla,
        triage,
        nhc
      )
    end)

    :ok
  end

  defp send_copy_data_async(
         from,
         type,
         data,
         hospital,
         isla,
         triage,
         nhc
       ) do
    # Sends the new data to the other clients
    clients = SysUsers.get_clients(hospital, isla)

    Enum.each(clients, fn pid ->
      if pid != nil and pid != from and Process.alive?(pid) do
        send(pid, {:copy_data, type, data, triage, nhc})
      end
    end)
  end

  def websocket_info({:copy_data, type, data, triage, nhc}, state) do
    id = UUIDgen.uuidgen()

    msg = %{
      version: "0.0",
      method: "copy_data",
      id: id,
      params: %{tipo: type, dato: data, triage: triage, nHC: nhc},
      token: state.token
    }

    msg = Poison.encode!(msg)
    {:reply, [{:text, msg}], state}
  end

  def websocket_info(msg, state) do
    Logger.debug([
      Atom.to_string(__MODULE__),
      " websocket_info:",
      inspect(msg)
    ])

    {:ok, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end
end
