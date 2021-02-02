defmodule Hospitales do
  use GenServer
  import Ecto.Query
  import UUIDgen

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

  def get_datos_usuario(cuil) do
    GenServer.call(__MODULE__, {:get_datos_usuario, cuil})
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_usuarios}, _from, state) do
    usuarios = CCloud.Repo.all(from(r in Hospitales.Usuario, select: r))

    {:reply, usuarios, state}
  end

  def handle_call({:new_hospital, hospital}, _from, state) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:registro, struct(Hospital, hospital))
    |> Ecto.Multi.insert(:sync_id_isla, %CCloud.Repo.SyncIDHosp{
      idHosp: hospital.idHosp,
      sync_id: 0
    })
    |> CCloud.Repo.transaction()

    Hospitales.Supervisor.new_hospital(hospital.idHosp, 0)

    {:reply, 0, state}
  end

  def handle_call({:new_usuario, usuario}, _from, state) do
    sal = uuidgen()

    salted =
      :crypto.hash(:sha512, usuario.clave <> sal)
      |> Base.encode16(case: :lower)

    usuario = Map.put(usuario, :sal, sal)
    usuario = Map.put(usuario, :clave, salted)
    CCloud.Repo.insert(struct(Hospitales.Usuario, usuario))
    {:reply, usuario, state}
  end

  def handle_call({:get_datos_usuario, cuil}, _from, state) do
    usuario =
      CCloud.Repo.one(
        from(r in Hospitales.Usuario,
          where: r.cuil == ^cuil,
          select: r
        )
      )
      |> Map.delete(:sal)
      |> Map.delete(:clave)

    roles =
      CCloud.Repo.all(
        from(r in Hospital.UsuarioHospital,
          where: r.cuil == ^cuil,
          select: [:idHospital, :idRol]
        )
      )
      |> Enum.reduce(%{}, fn %{idHospital: idHospital, idRol: idRol}, acc ->
        if acc[idHospital] == nil do
          Map.put(acc, idHospital, [idRol])
        else
          roles = acc[idHospital]
          Map.put(acc, idHospital, [idRol | roles])
        end
      end)

    sectores =
      CCloud.Repo.all(
        from(r in Hospital.UsuarioSector,
          where: r.cuil == ^cuil,
          select: [:idHospital, :idIsla, :idSector]
        )
      )
      |> Enum.reduce(%{}, fn %{
                               idHospital: idHospital,
                               idIsla: idIsla,
                               idSector: idSector
                             },
                             acc ->
        cond do
          acc[idHospital] == nil ->
            sectores = [idSector]
            hospital = Map.put(%{}, idIsla, sectores)
            Map.put(acc, idHospital, hospital)

          acc[idHospital][idIsla] == nil ->
            sectores = [idSector]
            hospital = Map.put(acc[idHospital], idIsla, sectores)
            Map.put(acc, idHospital, hospital)

          true ->
            sectores = [idSector | acc[idHospital][idIsla]]
            hospital = Map.put(acc[idHospital], idIsla, sectores)
            Map.put(acc, idHospital, hospital)
        end
      end)

    hospitales =
      Map.keys(sectores)
      |> Enum.concat(Map.keys(roles))
      |> Enum.uniq()

    hospitales =
      Enum.map(hospitales, fn idHospital ->
        %{sectores: sectores[idHospital], roles: roles[idHospital]}
      end)

    respuesta = %{usuario: usuario, hospitales: hospitales}

    {:reply, respuesta, state}
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

  def load() do
    import Ecto.Query

    hospitales =
      CCloud.Repo.all(
        from(r in CCloud.Repo.SyncIDHosp,
          select: r
        )
      )

    Enum.all?(
      hospitales,
      fn h ->
        new_hospital(h.idHosp, h.sync_id)
        Hospital.Supervisor.load(h.idHosp)
        IO.puts("new hospital")
        IO.puts(h.idHosp)
        true
      end
    )
  end

  def new_hospital(idHospital, sync_id) do
    children =
      Supervisor.child_spec(
        {Hospital, [idHospital: idHospital, sync_id: sync_id]},
        id: {Hospital, Utils.get_name_id(idHospital)}
      )

    DynamicSupervisor.start_child(__MODULE__, children)
  end
end

defmodule Hospitales.Usuario do
  use Ecto.Schema

  @primary_key false
  schema "Usuario" do
    field(:cuil, :string, primary_key: true)
    field(:clave, :string)
    field(:sal, :string)
    field(:nombre, :string)
    field(:apellido, :string)
    field(:email, :string)
    field(:telefono, :string)
  end
end
