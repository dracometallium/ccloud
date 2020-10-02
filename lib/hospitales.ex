defmodule Hospitales do
  use GenServer

  defstruct hospitales: [],
            usuarios: []

  def new_hospital(hospital) do
    GenServer.call(__MODULE__, {:new_hospital, hospital})
  end

  def new_usuario(usuario) do
    GenServer.call(__MODULE__, {:new_usuario, usuario})
  end

  def get_state() do
    GenServer.call(__MODULE__, {:get_state})
  end

  def get_usuarios() do
    GenServer.call(__MODULE__, {:get_usuarios})
  end

  def init(_opts) do
    {:ok, %Hospitales{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_usuarios}, _from, state) do
    {:reply, state.usuarios, state}
  end

  def handle_call({:new_hospital, hospital}, _from, state) do
    Hospitales.Supervisor.new_hospital(hospital.idHospital)

    state =
      Map.put(state, :hospitales, [hospital.idHospital | state.hospitales])

    sync_id = Hospital.set_hospital(hospital.idHospital, hospital)
    {:reply, sync_id, state}
  end

  def handle_call({:new_usuario, usuario}, _from, state) do
    usuario = struct(Hospitales.Usuario, usuario)
    state = Map.put(state, :usuarios, [usuario | state.usuarios])
    {:reply, usuario, state}
  end
end

defmodule Hospitales.Supervisor do
  use DynamicSupervisor

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def new_hospital(idHospital) do
    children =
      Supervisor.child_spec(
        {Hospital, [idHospital: idHospital]},
        id: {Hospital, Utils.get_name_id(idHospital)}
      )

    DynamicSupervisor.start_child(__MODULE__, children)
  end
end

defmodule Hospitales.Usuario do
  defstruct [
    :cuil,
    :clave,
    :nombre,
    :apellido,
    :email,
    :telefono
  ]
end
