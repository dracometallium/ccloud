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
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)

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

    q =
      from(u in Hospital.UsuarioSector,
        as: :usuario,
        where: u.cuil == ^cuil
      )

    q =
      from([usuario: u] in q,
        join: h in Hospital,
        as: :hospital,
        on: h.idHosp == u.idHospital
      )

    q =
      from([usuario: u, hospital: h] in q,
        join: s in Hospital.Sector,
        as: :sector,
        on: u.idIsla == s.idIsla and u.idSector == s.idSector,
        select: [s.idHospital, h.nombre, s.idIsla, s.idSector, s.descripcion]
      )

    sectores =
      CCloud.Repo.all(q)
      |> Enum.reduce(%{}, fn [
                               idHospital,
                               nombreHosp,
                               idIsla,
                               idSector,
                               descSector
                             ],
                             acc ->
        cond do
          acc[idHospital] == nil ->
            sectores = [%{idSector: idSector, descripcion: descSector}]
            islas = Map.put(%{}, idIsla, sectores)
            hospital = Map.put(%{nombre: nombreHosp}, :islas, islas)
            Map.put(acc, idHospital, hospital)

          acc[idHospital][idIsla] == nil ->
            sectores = [%{idSector: idSector, descripcion: descSector}]
            islas = Map.put(acc[idHospital][:islas], idIsla, sectores)
            hospital = Map.put(acc[idHospital], :islas, islas)
            Map.put(acc, idHospital, hospital)

          true ->
            sectores = [
              %{idSector: idSector, descripcion: descSector}
              | acc[idHospital][idIsla]
            ]

            islas = Map.put(acc[idHospital][:islas], idIsla, sectores)
            hospital = Map.put(acc[idHospital], :islas, islas)
            Map.put(acc, idHospital, hospital)
        end
      end)

    hospitales =
      Map.keys(sectores)
      |> Enum.concat(Map.keys(roles))
      |> Enum.uniq()

    reduce_islas = fn islas ->
      islas_k = Map.keys(islas)

      Enum.reduce(islas_k, [], fn isla, acc ->
        [
          %{idIsla: isla, sectores: islas[isla]} | acc
        ]
      end)
    end

    hospitales =
      Enum.reduce(hospitales, [], fn idHospital, acc ->
        [
          %{
            idHospital: idHospital,
            nombre: sectores[idHospital][:nombre],
            islas: reduce_islas.(sectores[idHospital][:islas]),
            roles: roles[idHospital]
          }
          | acc
        ]
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
