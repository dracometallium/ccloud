defmodule Hospital do
  use GenServer
  use Ecto.Schema
  import Utils
  import Ecto.Query

  @primary_key false
  schema "Hospital" do
    field(:sync_id, :integer)
    field(:idHosp, :string, primary_key: true)
    field(:nombre, :string)
    field(:calle, :string)
    field(:numero, :string)
    field(:cp, :string)
    field(:plano_camas, :string)
  end

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

  def init(opts) do
    state = %{sync_id: opts[:sync_id], idHosp: opts[:idHospital]}
    {:ok, state}
  end

  def start_link(opts) do
    hospital = opts[:idHospital]
    GenServer.start_link(__MODULE__, opts, name: get_name_id(hospital))
  end

  def handle_call({:new, table, registro}, _from, state) do
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

    if table == :islas do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:registro, registro)
      |> Ecto.Multi.insert(:sync_id_isla, %CCloud.Repo.SyncIDIsla{
        idHosp: state.idHosp,
        idIsla: registro.idIsla,
        sync_id: 0
      })
      |> Ecto.Multi.update(
        :max_sync_id,
        Ecto.Changeset.change(
          %CCloud.Repo.SyncIDHosp{
            idHosp: state.idHosp
          },
          sync_id: sync_id
        )
      )
      |> CCloud.Repo.transaction()

      Hospital.Supervisor.new_isla(state.idHosp, registro.idIsla, 0)
    else
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:registro, registro)
      |> Ecto.Multi.update(
        :max_sync_id,
        Ecto.Changeset.change(
          %CCloud.Repo.SyncIDHosp{
            idHosp: state.idHosp
          },
          sync_id: sync_id
        )
      )
      |> CCloud.Repo.transaction()
    end

    nstate = Map.put(state, :sync_id, sync_id)

    {:reply, sync_id, nstate}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get, :usuarios, sync_id}, from, state) do
    {_, usuarios_hospital, _} =
      handle_call({:get, :usuarios_hospital, sync_id}, from, state)

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
    result =
      case idH(table) do
        :idHospital ->
          CCloud.Repo.all(
            from(r in table2module(table),
              where:
                r.sync_id >= ^sync_id and
                  r.idHospital == ^state.idHosp,
              select: r
            )
          )

        :idHosp ->
          CCloud.Repo.all(
            from(r in table2module(table),
              where:
                r.sync_id >= ^sync_id and
                  r.idHosp == ^state.idHosp,
              select: r
            )
          )

        :idHospitalCama ->
          CCloud.Repo.all(
            from(r in table2module(table),
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalCama == ^state.idHosp,
              select: r
            )
          )

        :idHospitalLab ->
          CCloud.Repo.all(
            from(r in table2module(table),
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalLab == ^state.idHosp,
              select: r
            )
          )

        :idHospitalRad ->
          CCloud.Repo.all(
            from(r in table2module(table),
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalRad == ^state.idHosp,
              select: r
            )
          )

        :id_hospital ->
          CCloud.Repo.all(
            from(r in table2module(table),
              where:
                r.sync_id >= ^sync_id and
                  r.id_hospital == ^state.idHosp,
              select: r
            )
          )
      end

    {:reply, result, state}
  end

  def handle_call({:get_update, sync_id}, from, state) do
    list = [
      :camas,
      :hcpacientes,
      :islas,
      :sectores,
      :usuarios_hospital,
      :usuarios_sector,
      :hospitales
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
      :hospitales -> Hospital
    end
  end
end

defmodule Hospital.Supervisor do
  use DynamicSupervisor

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def load(idHosp) do
    import Ecto.Query

    islas =
      CCloud.Repo.all(
        from(r in CCloud.Repo.SyncIDIsla,
          select: r,
          where: r.idHosp == ^idHosp
        )
      )

    Enum.all?(
      islas,
      fn i ->
        Hospital.Supervisor.new_isla(i.idHosp, i.idIsla, i.sync_id)
        true
      end
    )
  end

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def new_isla(hospital, isla, sync_id) do
    children =
      Supervisor.child_spec(
        {Isla, [idIsla: isla, idHospital: hospital, sync_id: sync_id]},
        id: {Isla, Utils.get_name_id(hospital, isla)}
      )

    IO.inspect({Isla, Utils.get_name_id(hospital, isla)})

    DynamicSupervisor.start_child(__MODULE__, children)
  end
end

defmodule Hospital.UsuarioHospital do
  use Ecto.Schema

  @primary_key false
  schema "UsuarioHospital" do
    field(:sync_id, :integer)
    field(:sync_id_usuario, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:cuil, :string, primary_key: true)
    field(:idRol, :string, primary_key: true)
    field(:estadoLaboral, :integer)
  end
end

defmodule Hospital.Isla do
  use Ecto.Schema

  @primary_key false
  schema "Isla" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:idIsla, :string, primary_key: true)
    field(:idLider, :integer)
  end
end

defmodule Hospital.Sector do
  use Ecto.Schema

  @primary_key false
  schema "Sector" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:idIsla, :string, primary_key: true)
    field(:idSector, :integer, primary_key: true)
    field(:camaDesde, :string)
    field(:camaHasta, :string)
  end
end

defmodule Hospital.UsuarioSector do
  use Ecto.Schema

  @primary_key false
  schema "UsuarioSector" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:idIsla, :string, primary_key: true)
    field(:idSector, :integer, primary_key: true)
    field(:cuil, :string)
    field(:estado, :integer)
  end
end

defmodule Hospital.Cama do
  use Ecto.Schema

  @primary_key false
  schema "Cama" do
    field(:sync_id, :integer)
    field(:idHospitalCama, :string, primary_key: true)
    field(:idIsla, :string, primary_key: true)
    field(:idSector, :integer, primary_key: true)
    field(:idCama, :string, primary_key: true)
    field(:numeroHCPac, :string)
    field(:ubicacionX, :integer)
    field(:ubicacionY, :integer)
    field(:orientacion, :string)
    field(:estado, :string)
  end
end

defmodule Hospital.HCpaciente do
  use Ecto.Schema

  @primary_key false
  schema "HCpaciente" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:numeroHC, :string, primary_key: true)
    field(:tipoDocumento, :string)
    field(:paisExp, :string)
    field(:dni, :integer)
    field(:nombre, :string)
    field(:apellido, :string)
    field(:nacionalidad, :string)
    field(:genero, :string)
    field(:calle, :string)
    field(:numero, :string)
    field(:piso, :string)
    field(:CP, :string)
    field(:telefono, :string)
    field(:telefonoFamiliar, :string)
    field(:telefonoFamiliar2, :string)
    field(:fechaNac, :integer)
    field(:gravedad, :integer)
    field(:nivelConfianza, :integer)
    field(:auditoriaComorbilidades, :string)
    field(:iccGrado2, :integer)
    field(:epoc, :integer)
    field(:diabetesDanioOrgano, :integer)
    field(:hipertension, :integer)
    field(:obesidad, :integer)
    field(:enfermedadRenalCronica, :integer)
  end
end
