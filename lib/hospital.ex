defmodule Hospital do
  import Utils
  use GenServer

  defstruct sync_id: 0,
            idHosp: nil,
            nombre: nil,
            calle: nil,
            numero: nil,
            cp: nil,
            plano_camas: nil

  def new_cama(hospital, cama) do
    GenServer.call(get_name_id(hospital), {:new, :camas, cama})
  end

  def new_hcpaciente(hospital, hcpaciente) do
    GenServer.call(get_name_id(hospital), {:new, :hcpacientes, hcpaciente})
  end

  def new_isla(hospital, isla) do
    GenServer.call(get_name_id(hospital), {:new, :islas, isla})
  end

  def new_sector(hospital, sector) do
    GenServer.call(get_name_id(hospital), {:new, :sectores, sector})
  end

  def new_usuario_hospital(hospital, usuario_hospital) do
    GenServer.call(
      get_name_id(hospital),
      {:new, :usuarios_hospital, usuario_hospital}
    )
  end

  def new_usuario_sector(hospital, usuario_sector) do
    GenServer.call(
      get_name_id(hospital),
      {:new, :usuarios_sector, usuario_sector}
    )
  end

  def get_state(idHosp) do
    GenServer.call(get_name_id(idHosp), {:get_state})
  end

  def get_hospital(idHosp) do
    GenServer.call(get_name_id(idHosp), {:get, :hospital})
  end

  def get_usuarios(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :usuarios, sync_id})
  end

  def get_usuarios_hospital(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :usuarios_hospital, sync_id})
  end

  def get_usuarios_sector(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :usuarios_sector, sync_id})
  end

  def get_camas(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :camas, sync_id})
  end

  def get_hcpacientes(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :hcpacientes, sync_id})
  end

  def get_islas(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :islas, sync_id})
  end

  def get_sectores(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :sectores, sync_id})
  end

  def get_update(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get_update, sync_id})
  end

  def set_hospital(idHosp, hospital) do
    GenServer.call(get_name_id(idHosp), {:set, :hospital, hospital})
  end

  def init(opts) do
    state = %{
      sync_id: 0,
      hospital: %Hospital{
        idHosp: opts[:idHospital]
      },
      camas: {0, []},
      hcpacientes: {0, []},
      islas: {0, []},
      sectores: {0, []},
      usuarios_hospital: {0, []},
      usuarios_sector: {0, []}
    }

    {:ok, state}
  end

  def start_link(opts) do
    hospital = opts[:idHospital]
    GenServer.start_link(__MODULE__, opts, name: get_name_id(hospital))
  end

  def handle_call({:new, table, registro}, _from, state) do
    if table == :islas do
      Hospital.Supervisor.new_isla(registro.idHospital, registro.idIsla)
    end

    {_maxSync, registros} = Map.get(state, table)

    sync_id =
      if registro[:sync_id] == nil do
        state.sync_id + 1
      else
        registro.sync_id
      end

    {sync_id, registro} =
      if table == :usuarios_hospital do
        registro = Map.merge(registro, %{sync_id_usuario: sync_id + 1})
        {sync_id + 1, registro}
      else
        {sync_id, registro}
      end

    registro = struct(table2module(table), registro)
    registros = [Map.put(registro, :sync_id, sync_id) | registros]

    nstate =
      Map.put(state, table, {sync_id, registros})
      |> Map.put(:sync_id, sync_id)

    {:reply, sync_id, nstate}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get, :hospital}, _from, state) do
    {:reply, state.hospital, state}
  end

  def handle_call({:get, :usuarios, sync_id}, _from, state) do
    {_, usuarios_hospital} = state.usuarios_hospital

    usuarios_id =
      Enum.filter(
        usuarios_hospital,
        fn x -> x.sync_id_usuario > sync_id end
      )
      |> Enum.reduce(
        %{},
        fn x, acc ->
          Map.merge(acc, %{cuil: x.cuil, sync_id: x.sync_id_usuario})
        end
      )

    usuarios =
      Hospitales.get_usuarios()
      |> Enum.filter(fn x -> Enum.member?(usuarios_id, x) end)
      |> Enum.map(fn x -> Map.put(x, :sync_id, usuarios_id[x.cuil]) end)

    {:reply, usuarios, state}
  end

  def handle_call({:get, table, sync_id}, _from, state) do
    {l_sync, registros} = Map.get(state, table)

    result =
      if l_sync < sync_id do
        []
      else
        filter_syncid(registros, sync_id)
      end

    {:reply, result, state}
  end

  def handle_call({:set, :hospital, hospital}, _from, state) do
    sync_id = state.sync_id + 1

    hospital =
      Map.merge(state.hospital, hospital)
      |> Map.put(:sync_id, sync_id)

    state =
      Map.put(state, :hospital, hospital)
      |> Map.put(:sync_id, sync_id)

    {:reply, state.hospital, state}
  end

  def handle_call({:get_update, sync_id}, from, state) do
    list = [
      :camas,
      :hcpacientes,
      :islas,
      :sectores,
      :usuarios_hospital,
      :usuarios_sector
    ]

    hospital =
      if state.hospital.sync_id > sync_id do
        state.hospital
      else
        nil
      end

    {_, usuarios, _} = handle_call({:get, :usuarios, sync_id}, from, state)

    result =
      get_fromlist(list, sync_id, state)
      |> Map.merge(%{hospital: hospital})
      |> Map.merge(%{usuarios: usuarios})

    {:reply, result, state}
  end

  def handle_call({:inc_sync_id}, _from, state) do
    state = Map.put(state, :sync_id, state.sync_id)
    {:reply, state.sync_id, state}
  end

  defp get_fromlist(list, sync_id, state) do
    get_fromlist(list, sync_id, %{}, state)
  end

  defp get_fromlist([], _sync_id, input, _state) do
    input
  end

  defp get_fromlist([head | tail], sync_id, input, state) do
    {_, list, _} = handle_call({:get, head, sync_id}, self(), state)
    input = Map.put(input, head, list)
    get_fromlist(tail, sync_id, input, state)
  end

  defp table2module(table) do
    case table do
      :usuarios_hospital -> Hospital.UsuarioHospital
      :islas -> Hospital.Isla
      :sectores -> Hospital.Sector
      :usuarios_sector -> Hospital.UsuarioSector
      :camas -> Hospital.Cama
      :hcpacientes -> Hospital.HCpaciente
    end
  end
end

defmodule Hospital.Supervisor do
  use DynamicSupervisor

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def new_isla(hospital, isla) do
    children =
      Supervisor.child_spec(
        {Isla, [idIsla: isla, idHospital: hospital]},
        id: {Isla, Utils.get_name_id(hospital, isla)}
      )

    IO.inspect({Isla, Utils.get_name_id(hospital, isla)})

    IO.inspect(DynamicSupervisor.start_child(__MODULE__, children))
  end
end

defmodule Hospital.UsuarioHospital do
  defstruct([
    :sync_id,
    :sync_id_usuario,
    :idHospital,
    :cuil,
    :idRol,
    :estadoLaboral
  ])
end

defmodule Hospital.Isla do
  defstruct [
    :sync_id,
    :idHospital,
    :idIsla,
    :idLider
  ]
end

defmodule Hospital.Sector do
  defstruct [
    :sync_id,
    :idHospital,
    :idIsla,
    :idSector,
    :camaDesde,
    :camaHasta
  ]
end

defmodule Hospital.UsuarioSector do
  defstruct [
    :sync_id,
    :idHospital,
    :idIsla,
    :idSector,
    :cuil,
    :estado
  ]
end

defmodule Hospital.Cama do
  defstruct [
    :sync_id,
    :idHospital,
    :idIsla,
    :idSector,
    :idCama,
    :numeroHCPac,
    :ubicacionX,
    :ubicacionY,
    :orientacion,
    :estado
  ]
end

defmodule Hospital.HCpaciente do
  defstruct [
    :sync_id,
    :idHospital,
    :numeroHC,
    :tipoDocumento,
    :paisExp,
    :dni,
    :nombre,
    :apellido,
    :nacionalidad,
    # :sexo_biologico,
    :genero,
    :calle,
    :numero,
    :piso,
    :CP,
    :telefono,
    :telefonoFamiliar1,
    :telefonoFamiliar2,
    :fechaNac,
    :gravedad,
    :nivelConfianza,
    :auditoriaComorbilidades,
    :iccGrado2,
    :epoc,
    :diabetesDanioOrgano,
    :hipertension,
    :obesidad,
    :enfermedadRenalCronica
  ]
end
