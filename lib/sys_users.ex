defmodule SysUsers do
  use GenServer
  import UUIDgen

  # cantidad de segundos para el timeout.
  @timeout 3600
  # cantidad de segundos para el timeout del tick.
  @tick_timeout 300

  defstruct connected: %{}, lideres: %{}

  defp autenticate(:system, _user, _password) do
    # TODO: realmente chequear
    true
  end

  defp autenticate(_hospital, _user, _password) do
    # TODO: realmente chequear
    true
  end

  def hello(user, password, hospital, isla, sector, token, pid) do
    if autenticate(hospital, user, password) do
      GenServer.call(
        __MODULE__,
        {:hello_user, user, hospital, isla, sector, token, pid}
      )
    else
      nil
    end
  end

  def hello(user, password, hospital, isla, sector, pid) do
    if autenticate(hospital, user, password) do
      GenServer.call(
        __MODULE__,
        {:hello_user, user, hospital, isla, sector, nil, pid}
      )
    else
      nil
    end
  end

  def hello(user, password, hospital, pid) do
    if autenticate(hospital, user, password) do
      GenServer.call(
        __MODULE__,
        {:hello_user, user, hospital, nil, nil, nil, pid}
      )
    else
      nil
    end
  end

  def hello(user, password, pid) do
    if autenticate(:system, user, password) do
      GenServer.call(__MODULE__, {:hello_user, user, nil, nil, nil, nil, pid})
    else
      nil
    end
  end

  def add_lider(token) do
    GenServer.call(__MODULE__, {:add_lider, token})
  end

  def get_lider(hospital, isla) do
    GenServer.call(__MODULE__, {:get_lider, hospital, isla})
  end

  def get_connection(token) do
    GenServer.call(__MODULE__, {:get_connection, token})
  end

  def update_connection(token) do
    GenServer.cast(__MODULE__, {:update_connection, token})
  end

  def init(_opts) do
    spawn(fn -> tick() end)
    {:ok, %SysUsers{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  defp tick() do
    :timer.sleep(@tick_timeout * 1000)
    GenServer.call(__MODULE__, {:clean_connected})
    tick()
  end

  defp clean_connected([], connected, _time) do
    connected
  end

  defp clean_connected(list_keys, connected, time) do
    [head | tail] = list_keys

    connected =
      if connected[head].timeout < time do
        Map.delete(connected, head)
      else
        connected
      end

    clean_connected(tail, connected, time)
  end

  def handle_call({:clean_connected}, _from, state) do
    connected =
      clean_connected(
        Map.keys(state.connected),
        state.connected,
        :os.system_time(:seconds)
      )

    state = Map.put(state, :connected, connected)
    {:reply, nil, state}
  end

  def handle_call(
        {:hello_user, user, hospital, isla, sector, token, pid},
        _from,
        state
      ) do
    token =
      if token == nil do
        uuidgen()
      else
        token
      end

    connection = %{
      user: user,
      hospital: hospital,
      isla: isla,
      sector: sector,
      pid: pid,
      timeout: :os.system_time(:seconds) + @timeout
    }

    connected = Map.put(state.connected, token, connection)
    state = Map.put(state, :connected, connected)
    {:reply, token, state}
  end

  def handle_call({:get_connection, token}, _from, state) do
    connection = state.connected[token]

    if connection != nil do
      {_, state} = handle_cast({:update_connection, token}, state)
      connection = Map.delete(connection, :timeout)
      {:reply, connection, state}
    else
      {:reply, nil, state}
    end
  end

  def handle_call({:add_lider, token}, from, state) do
    hospital = state.connected[token].hopital
    isla = state.connected[token].isla

    {_, pid, _} = handle_call({:get_lider, hospital, isla}, from, state)

    cond do
      pid != nil ->
        {:reply, :cant, state}

      hospital == nil or isla == nil ->
        {:reply, :error, state}

      true ->
        lideres = Map.put(state.lideres, {hospital, isla}, token)
        state = Map.put(state, :lideres, lideres)
        {:reply, :ok, state}
    end
  end

  def handle_call({:get_lider, hospital, isla}, _from, state) do
    token = state.lideres[{hospital, isla}]
    pid = state.connected[token][:pid]

    cond do
      pid == nil -> {:reply, nil, state}
      Process.alive?(pid) -> {:reply, pid, state}
      true -> {:reply, nil, state}
    end
  end

  def handle_cast({:update_connection, token}, state) do
    connection = state.connected[token]

    state =
      if connection != nil do
        connection =
          Map.put(connection, :timeout, :os.system_time(:seconds) + @timeout)

        connected = Map.put(state.connected, token, connection)
        Map.put(state, :connected, connected)
      end

    {:noreply, state}
  end
end

defmodule SysUsers.Connection do
  defstruct user: nil,
            hospital: nil,
            isla: nil,
            sector: nil,
            timeout: nil,
            pid: nil
end
