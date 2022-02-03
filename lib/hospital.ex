defmodule Hospital do
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
    new(hospital, :camas, cama)
  end

  def new_isla(hospital, isla) do
    new(hospital, :islas, isla)
  end

  def new_sector(hospital, sector) do
    new(hospital, :sectores, sector)
  end

  def new_usuario_hospital(hospital, usuario_hospital) do
    new(hospital, :usuarios_hospital, usuario_hospital)
  end

  def new_usuario_sector(hospital, usuario_sector) do
    new(hospital, :usuarios_sector, usuario_sector)
  end

  def modify_cama(hospital, cama) do
    modify(hospital, :camas, cama)
  end

  def modify_isla(hospital, isla) do
    modify(hospital, :islas, isla)
  end

  def modify_sector(hospital, sector) do
    modify(hospital, :sectores, sector)
  end

  def modify_usuario_hospital(hospital, usuario_hospital) do
    modify(hospital, :usuarios_hospital, usuario_hospital)
  end

  def modify_usuario_sector(hospital, usuario_sector) do
    modify(hospital, :usuarios_sector, usuario_sector)
  end

  def modify_hospital(hospital, dato_hospital) do
    modify(hospital, :hospitales, dato_hospital)
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

  def get_hospital(idHosp) do
    get(idHosp, :hospitales, 0)
  end

  def get_usuarios(hospital, sync_id) do
    get(hospital, :usuarios, sync_id)
  end

  def get_usuarios_hospital(hospital, sync_id) do
    get(hospital, :usuarios_hospital, sync_id)
  end

  def get_datos_usuario(hospital, cuil) do
    get_datos_usuario(hospital, cuil)
  end

  def get_usuarios_sector(hospital, sync_id) do
    get(hospital, :usuarios_sector, sync_id)
  end

  def get_camas(hospital, sync_id) do
    get(hospital, :camas, sync_id)
  end

  def get_islas(hospital, sync_id) do
    get(hospital, :islas, sync_id)
  end

  def get_sectores(hospital, sync_id) do
    get(hospital, :sectores, sync_id)
  end

  def new(idHosp, table, registro) do
    table = table2module(table)
    registro = cast_all(table, registro)

    registro = struct(table, registro)

    status =
      Ecto.Multi.new()
      |> Ecto.Multi.run(
        :sync_id,
        fn _, _ ->
          r =
            CCloud.Repo.get_by(
              CCloud.Repo.SyncIDHosp,
              idHosp: idHosp
            )

          case r do
            nil ->
              {:error, nil}

            _ ->
              {:ok, r.sync_id + 1}
          end
        end
      )
      |> Ecto.Multi.insert(:registro, fn %{sync_id: sync_id} ->
        Map.put(registro, :sync_id, sync_id)
      end)
      |> (fn q ->
            case table do
              Hospital.Isla ->
                q
                |> Ecto.Multi.insert(:sync_id_isla, %CCloud.Repo.SyncIDIsla{
                  idHosp: idHosp,
                  idIsla: registro.idIsla,
                  sync_id: 0
                })

              Hospital.UsuarioHospital ->
                q
                |> Ecto.Multi.update(
                  :sync_id_usuario_hospital,
                  fn %{sync_id: sync_id} ->
                    Ecto.Changeset.change(
                      registro,
                      sync_id_usuario: sync_id + 1
                    )
                  end
                )

              _ ->
                q
            end
          end).()
      |> Ecto.Multi.update(
        :max_sync_id,
        fn %{sync_id: sync_id} ->
          Ecto.Changeset.change(
            %CCloud.Repo.SyncIDHosp{
              idHosp: idHosp
            },
            sync_id: sync_id
          )
        end
      )
      |> CCloud.Repo.transaction()

    case status do
      {:ok, result} ->
        sync_id = result[:sync_id]
        sync_id

      _ ->
        :error
    end
  end

  def modify(idHosp, table, registro) do
    table = table2module(table)
    registro = cast_all(table, registro)

    keys =
      Map.take(
        registro,
        Keyword.keys(Ecto.primary_key(struct(table, registro)))
      )

    keys = struct(table, keys)

    status =
      Ecto.Multi.new()
      |> Ecto.Multi.run(
        :sync_id,
        fn _, _ ->
          r =
            CCloud.Repo.get_by(
              CCloud.Repo.SyncIDHosp,
              idHosp: idHosp
            )

          case r do
            nil ->
              {:error, nil}

            _ ->
              {:ok, r.sync_id + 1}
          end
        end
      )
      |> Ecto.Multi.update(:registro, fn %{sync_id: sync_id} ->
        registro = Map.put(registro, :sync_id, sync_id)
        Ecto.Changeset.change(keys, registro)
      end)
      |> Ecto.Multi.update(
        :max_sync_id,
        fn %{sync_id: sync_id} ->
          Ecto.Changeset.change(
            %CCloud.Repo.SyncIDHosp{
              idHosp: idHosp
            },
            sync_id: sync_id
          )
        end
      )
      |> CCloud.Repo.transaction()

    case status do
      {:ok, result} ->
        sync_id = result[:sync_id]
        sync_id

      _ ->
        :error
    end
  end

  def get(idHosp, :usuarios, sync_id) do
    usuarios_hospital = get(idHosp, :usuarios_hospital, sync_id)

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
      |> Enum.map(fn x ->
        Map.put(
          x,
          :sync_id,
          usuarios_id[x.cuil]
        )
        |> Map.delete(:__meta__)
        |> Map.delete(:__struct__)
      end)

    usuarios
  end

  def get(idHosp, table, sync_id) do
    table = table2module(table)

    result =
      case idH(table) do
        :idHospital ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospital == ^idHosp,
              select: r
            )
          )

        :idHosp ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHosp == ^idHosp,
              select: r
            )
          )

        :idHospitalCama ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalCama == ^idHosp,
              select: r
            )
          )

        :idHospitalLab ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalLab == ^idHosp,
              select: r
            )
          )

        :idHospitalRad ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.idHospitalRad == ^idHosp,
              select: r
            )
          )

        :id_hospital ->
          CCloud.Repo.all(
            from(r in table,
              where:
                r.sync_id >= ^sync_id and
                  r.id_hospital == ^idHosp,
              select: r
            )
          )
      end

    result = Enum.map(result, fn x -> clean(table, x) end)
    result
  end

  def get_update(idHosp, sync_id) do
    list = [
      :camas,
      :islas,
      :sectores,
      :usuarios_hospital,
      :usuarios_sector
    ]

    hospital =
      CCloud.Repo.one(
        from(r in Hospital,
          where: r.idHosp == ^idHosp and r.sync_id > ^sync_id
        )
      )

    hospital =
      if hospital != nil do
        hospital
        |> Map.delete(:__meta__)
        |> Map.delete(:__struct__)
      end

    usuarios = get(idHosp, :usuarios, sync_id)

    result =
      Enum.reduce(list, %{}, fn x, acc ->
        list = get(idHosp, x, sync_id)
        Map.put(acc, x, list)
      end)
      |> Map.merge(%{hospital: hospital})
      |> Map.merge(%{usuarios: usuarios})

    result
  end

  def get_sync_id(idHosp) do
    r =
      CCloud.Repo.get_by(
        CCloud.Repo.SyncIDHosp,
        idHosp: idHosp
      )

    r.sync_id
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
    field(:estadoLaboral, :integer, default: 0)
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
    field(:estado, :integer, default: 0)
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
    field(:estado, :integer, default: 0)
  end
end
