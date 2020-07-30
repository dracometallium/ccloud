defmodule Hospital do
  import Utils
  use GenServer

  defstruct sync_id: 0,
            id_hospital: nil,
            nombre: nil,
            calle: nil,
            numero: nil,
            cp: nil,
            plano_camas: nil

  def new_cama(hospital, cama) do
    GenServer.call(get_name_id(hospital), {:new, :camas, cama})
  end

  def new_hcpasiente(hospital, hcpasiente) do
    GenServer.call(get_name_id(hospital), {:new, :hcpasientes, hcpasiente})
  end

  def new_isla(hospital, isla) do
    GenServer.call(get_name_id(hospital), {:new, :islas, isla})
  end

  def new_sector(hospital, sector) do
    GenServer.call(get_name_id(hospital), {:new, :sectors, sector})
  end

  def new_usuario_hospital(hospital, usuario_hospital) do
    GenServer.call(get_name_id(hospital), {:new, :usuarios_hospital, usuario_hospital})
  end

  def new_usuario_sector(hospital, usuario_sector) do
    GenServer.call(get_name_id(hospital), {:new, :usuarios_sector, usuario_sector})
  end

  def get_state(id_hospital) do
    GenServer.call(get_name_id(id_hospital), {:get_state})
  end

  def get_hospital(id_hospital) do
    GenServer.call(get_name_id(id_hospital), {:get, :hospital})
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

  def get_hcpasientes(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :hcpasientes, sync_id})
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

  def set_hospital(id_hospital, hospital) do
    GenServer.call(get_name_id(id_hospital), {:set, :hospital, hospital})
  end

  def init(opts) do
    state = %{
      sync_id: 0,
      hospital: %Hospital{
        id_hospital: opts[:id_hospital]
      },
      camas: {0, []},
      hcpasientes: {0, []},
      islas: {0, []},
      sectores: {0, []},
      usuarios_hospital: {0, []},
      usuarios_sector: {0, []}
    }

    {:ok, state}
  end

  def start_link(opts) do
    hospital = opts[:id_hospital]
    GenServer.start_link(__MODULE__, opts, name: get_name_id(hospital))
  end

  def handle_call({:new, table, registro}, _from, state) do
    if table == :islas do
      Hospital.Supervisor.new_isla(registro.id_hospital, registro.id_isla)
    end

    {_maxSync, registros} = Map.get(state, table)

    sync_id =
      if registro[:sync_id] == nil do
        state.sync_id + 1
      else
        registro.sync_id
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
      :hcpasientes,
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
      :usuarioshospital -> Hospital.UsuarioHospital
      :islas -> Hospital.Isla
      :sectores -> Hospital.Sector
      :usuariossector -> Hospital.UsuarioSector
      :camas -> Hospital.Cama
      :hcpasientes -> Hospital.HCpasiente
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
        {Isla, [id_isla: isla, id_hospital: hospital]},
        id: {Isla, Utils.get_name_id(hospital, isla)}
      )

    DynamicSupervisor.start_child(__MODULE__, children)
  end
end

defmodule Hospital.UsuarioHospital do
  defstruct [
    :sync_id,
    :sync_id_usuario,
    :id_hospital,
    :cuil,
    :id_rol,
    :estado_laboral
  ]
end

defmodule Hospital.Isla do
  defstruct [
    :sync_id,
    :id_hospital,
    :id_isla,
    :id_lider
  ]
end

defmodule Hospital.Sector do
  defstruct [
    :sync_id,
    :id_hospital,
    :id_isla,
    :id_sector,
    :nombre_sector,
    :camas
  ]
end

defmodule Hospital.UsuarioSector do
  defstruct [
    :sync_id,
    :id_hospital,
    :id_isla,
    :id_sector,
    :cuil,
    :estado
  ]
end

defmodule Hospital.Cama do
  defstruct [
    :sync_id,
    :id_hospital,
    :id_isla,
    :id_sector,
    :id_cama,
    :nhc,
    :ubicacion_x,
    :ubicacion_y,
    :orientacion_grados
  ]
end

defmodule Hospital.HCpasiente do
  defstruct [
    :sync_id,
    :id_hospital,
    :nhc,
    :tipo_documento,
    :pais_de_expedicion,
    :ndocumento,
    :nombres,
    :apellidos,
    :nacionalidad,
    :sexo_biologico,
    :calle,
    :numero,
    :piso_y_depto,
    :cp,
    :telefono,
    :telefono_familiar_1,
    :telefono_familiar_2,
    :fecha_nacimiento,
    :gravedad,
    :nivel_de_confianza,
    :auditoria_comorbilidades,
    :icc_grado_2_o_mas,
    :epoc,
    :diabetes_con_danno_de_organo_blanco,
    :hipertension,
    :enfermedad_renal_cronica
  ]
end
