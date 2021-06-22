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
    field(:planoCamas, :string)
  end

  def new_cama(hospital, cama) do
    GenServer.call(get_name_id(hospital), {:new, :camas, cama})
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

  def modify_cama(hospital, cama) do
    GenServer.call(get_name_id(hospital), {:modify, :camas, cama})
  end

  def modify_isla(hospital, isla) do
    GenServer.call(get_name_id(hospital), {:modify, :islas, isla})
  end

  def modify_sector(hospital, sector) do
    GenServer.call(get_name_id(hospital), {:modify, :sectores, sector})
  end

  def modify_usuario_hospital(hospital, usuario_hospital) do
    GenServer.call(
      get_name_id(hospital),
      {:modify, :usuarios_hospital, usuario_hospital}
    )
  end

  def modify_usuario_sector(hospital, usuario_sector) do
    GenServer.call(
      get_name_id(hospital),
      {:modify, :usuarios_sector, usuario_sector}
    )
  end

  def modify_hospital(hospital, dato_hospital) do
    GenServer.call(
      get_name_id(hospital),
      {:modify, :hospitales, dato_hospital}
    )
  end

  def get_isla(idHosp, idSector) do
    query =
      from(r in Hospital.Sector,
        where:
          r.idSector == ^idSector and
            r.idHospital == ^idHosp,
        select: r.idIsla
      )

    CCloud.Repo.one(query)
  end

  def get_state(idHosp) do
    GenServer.call(get_name_id(idHosp), {:get_state})
  end

  def get_hospital(idHosp) do
    GenServer.call(get_name_id(idHosp), {:get, :hospitales})
  end

  def get_usuarios(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :usuarios, sync_id})
  end

  def get_usuarios_hospital(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :usuarios_hospital, sync_id})
  end

  def get_datos_usuario(hospital, cuil) do
    GenServer.call(get_name_id(hospital), {:get_datos_usuario, cuil})
  end

  def get_usuarios_sector(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :usuarios_sector, sync_id})
  end

  def get_camas(hospital, sync_id) do
    GenServer.call(get_name_id(hospital), {:get, :camas, sync_id})
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

  def get_sync_id(hospital) do
    GenServer.call(get_name_id(hospital), {:get_sync_id})
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

    table = table2module(table)

    registro =
      cast_all(table, registro)
      |> Map.put(:sync_id, sync_id)

    registro = struct(table, registro)

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

  def handle_call({:modify, table, registro}, _from, state) do
    sync_id =
      if registro[:sync_id] == nil do
        state.sync_id + 1
      else
        registro.sync_id
      end

    table = table2module(table)

    registro =
      cast_all(table, registro)
      |> Map.put(:sync_id, sync_id)

    keys =
      Map.take(
        registro,
        Keyword.keys(Ecto.primary_key(struct(table, registro)))
      )

    keys = struct(table, keys)
    IO.inspect(struct(table, registro))
    IO.inspect(keys)

    registro = Ecto.Changeset.change(keys, registro)
    IO.inspect(registro)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:registro, registro)
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
          Map.merge(acc, %{x.cuil => x.sync_id_usuario})
        end
      )

    usuarios =
      Hospitales.get_usuarios()
      |> Enum.filter(fn x -> Map.has_key?(usuarios_id, x.cuil) end)
      |> Enum.map(fn x -> Map.put(x, :sync_id, usuarios_id[x.cuil]) end)

    {:reply, usuarios, state}
  end

  def handle_call({:get, table, sync_id}, _from, state) do
    table = table2module(table)

    result =
      case idH(table) do
        :idHospital ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospital == ^state.idHosp,
              select: r
            )
          )

        :idHosp ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHosp == ^state.idHosp,
              select: r
            )
          )

        :idHospitalCama ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalCama == ^state.idHosp,
              select: r
            )
          )

        :idHospitalLab ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalLab == ^state.idHosp,
              select: r
            )
          )

        :idHospitalRad ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalRad == ^state.idHosp,
              select: r
            )
          )

        :id_hospital ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.id_hospital == ^state.idHosp,
              select: r
            )
          )
      end

    result = Enum.map(result, fn x -> clean(table, x) end)
    {:reply, result, state}
  end

  def handle_call({:get_update, sync_id}, from, state) do
    list = [
      :camas,
      :islas,
      :sectores,
      :usuarios_hospital,
      :usuarios_sector
    ]

    hospital =
      if state.sync_id > sync_id do
        CCloud.Repo.one(
          from(r in Hospital,
            where: r.idHosp == ^state.idHosp
          )
        )
      else
        nil
      end

    {_, usuarios, _} = handle_call({:get, :usuarios, sync_id}, from, state)

    result =
      Enum.reduce(list, %{}, fn x, acc ->
        {_, list, _} = handle_call({:get, x, sync_id}, self(), state)
        Map.put(acc, x, list)
      end)
      |> Map.merge(%{hospital: hospital})
      |> Map.merge(%{usuarios: usuarios})

    {:reply, result, state}
  end

  def handle_call({:get_sync_id}, _from, state) do
    {:reply, state.sync_id, state}
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
        IO.puts("new isla")
        IO.puts(i.idHosp)
        IO.puts(i.idIsla)
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
    field(:idRol, :integer, primary_key: true)
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
    field(:idIsla, :string)
    field(:idSector, :string, primary_key: true)
    field(:descripcion, :string)
  end
end

defmodule Hospital.UsuarioSector do
  use Ecto.Schema

  @primary_key false
  schema "UsuarioSector" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:idSector, :string, primary_key: true)
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
    field(:idSector, :string, primary_key: true)
    field(:idCama, :string, primary_key: true)
    field(:numeroHCPac, :string)
    field(:ubicacionX, :integer)
    field(:ubicacionY, :integer)
    field(:orientacion, :string)
    field(:estado, :integer)
  end
end
