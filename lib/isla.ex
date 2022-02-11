defmodule Isla do
  use Ecto.Schema
  import Ecto.Query
  import Utils

  def plural, do: :islas

  def new_signo_vital(hospital, isla, signo_vital) do
    new(hospital, isla, Isla.SignosVitales, signo_vital)
  end

  def new_laboratorio(hospital, isla, laboratorio) do
    new(hospital, isla, Isla.Laboratorio, laboratorio)
  end

  def new_rx_torax(hospital, isla, rx_torax) do
    new(hospital, isla, Isla.RxTorax, rx_torax)
  end

  def new_alerta(hospital, isla, alerta) do
    new(hospital, isla, Isla.Alerta, alerta)
  end

  def new_episodio(hospital, isla, episodio) do
    new(hospital, isla, Isla.Episodio, episodio)
  end

  def new_hcpaciente(hospital, isla, hcpaciente) do
    new(hospital, isla, Isla.HCpaciente, hcpaciente)
  end

  def new_alerta_vista(hospital, numerohc, fechaAlerta, cuil) do
    try do
      alertaVista = %{
        idHospital: hospital,
        numeroHC: numerohc,
        fechaAlerta: fechaAlerta,
        cuil: cuil
      }

      alertaVista = struct(Isla.AlertaVista, alertaVista)

      CCloud.Repo.insert(alertaVista)
      :ok
    rescue
      reason -> {:error, reason}
    end
  end

  def modify_signo_vital(hospital, isla, signo_vital) do
    modify(hospital, isla, Isla.SignosVitales, signo_vital)
  end

  def modify_laboratorio(hospital, isla, laboratorio) do
    modify(hospital, isla, Isla.Laboratorio, laboratorio)
  end

  def modify_rx_torax(hospital, isla, rx_torax) do
    modify(hospital, isla, Isla.RxTorax, rx_torax)
  end

  def modify_alerta(hospital, isla, alerta) do
    modify(hospital, isla, Isla.Alerta, alerta)
  end

  def modify_episodio(hospital, isla, episodio) do
    modify(hospital, isla, Isla.Episodio, episodio)
  end

  def modify_hcpaciente(hospital, isla, hcpaciente) do
    modify(hospital, isla, Isla.HCpaciente, hcpaciente)
  end

  def copy_signo_vital(hospital, isla, signo_vital) do
    copy(hospital, isla, Isla.SignosVitales, signo_vital)
  end

  def copy_laboratorio(hospital, isla, laboratorio) do
    copy(hospital, isla, Isla.Laboratorio, laboratorio)
  end

  def copy_rx_torax(hospital, isla, rx_torax) do
    copy(hospital, isla, Isla.RxTorax, rx_torax)
  end

  def copy_alerta(hospital, isla, alerta) do
    copy(hospital, isla, Isla.Alerta, alerta)
  end

  def copy_episodio(hospital, isla, episodio) do
    copy(hospital, isla, Isla.Episodio, episodio)
  end

  def copy_hcpaciente(hospital, isla, hcpaciente) do
    copy(hospital, isla, Isla.HCpaciente, hcpaciente)
  end

  def get_signos_vitales(hospital, isla, sector, sync_id) do
    get(hospital, isla, Isla.SignosVitales, sector, sync_id, nil)
  end

  def get_laboratorios(hospital, isla, sector, sync_id) do
    get(hospital, isla, Isla.Laboratorio, sector, sync_id, nil)
  end

  def get_rx_toraxs(hospital, isla, sector, sync_id) do
    get(hospital, isla, Isla.RxTorax, sector, sync_id, nil)
  end

  def get_alertas(hospital, isla, sector, sync_id) do
    get(hospital, isla, Isla.Alerta, sector, sync_id, nil)
  end

  def get_alertas(hospital, isla, sector, cuil, sync_id) do
    filter = fn q ->
      from(a in q,
        left_join: v in Isla.AlertaVista,
        as: :alertaVista,
        on:
          a.idHospital == v.idHospital and
            a.numeroHC == v.numeroHC and
            a.fechaAlerta == v.fechaAlerta,
        where: is_nil(v.cuil) or v.cuil != ^cuil
      )
    end

    get(hospital, isla, Isla.Alerta, sector, sync_id, filter)
  end

  def get_episodios(hospital, isla, sector, sync_id) do
    get(hospital, isla, Isla.Episodio, sector, sync_id, nil)
  end

  def get_hcpacientes(hospital, isla, sector, sync_id) do
    get(hospital, isla, Isla.HCpaciente, sector, sync_id, nil)
  end

  def new(idHosp, idIsla, table, registro) do
    registro = cast_all(table, registro)

    registro = struct(table, registro)

    status =
      Ecto.Multi.new()
      |> Ecto.Multi.run(
        :sync_id,
        fn _, _ ->
          r =
            CCloud.Repo.get_by(
              CCloud.Repo.SyncIDIsla,
              idHosp: idHosp,
              idIsla: idIsla
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
      |> Ecto.Multi.update(
        :max_sync_id,
        fn %{sync_id: sync_id} ->
          Ecto.Changeset.change(
            %CCloud.Repo.SyncIDIsla{
              idHosp: idHosp,
              idIsla: idIsla
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

  def modify(idHosp, idIsla, table, registro) do
    registro = cast_all(table, registro)

    status =
      Ecto.Multi.new()
      |> Ecto.Multi.run(
        :sync_id,
        fn _, _ ->
          r =
            CCloud.Repo.get_by(
              CCloud.Repo.SyncIDIsla,
              idHosp: idHosp,
              idIsla: idIsla
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
        k = struct(table, keys(table, registro))
        Ecto.Changeset.change(k, registro)
      end)
      |> Ecto.Multi.update(
        :max_sync_id,
        fn %{sync_id: sync_id} ->
          Ecto.Changeset.change(
            %CCloud.Repo.SyncIDIsla{
              idHosp: idHosp,
              idIsla: idIsla
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

  def copy(idHosp, idIsla, table, registros) do
    registros = List.wrap(registros)

    sync_id_reg =
      Enum.reduce(
        registros,
        0,
        fn r, acc ->
          max(acc, r.sync_id)
        end
      )

    registros =
      Enum.map(
        registros,
        fn r ->
          {cast_all(table, r), keys(table, r)}
        end
      )

    status =
      Ecto.Multi.new()
      |> Ecto.Multi.run(
        :changesets,
        fn _, _ ->
          changeset =
            Enum.map(
              registros,
              fn {r, k} ->
                case CCloud.Repo.get_by(table, k) do
                  nil -> struct(table, k)
                  reg -> reg
                end
                |> Ecto.Changeset.change(r)
              end
            )

          {:ok, changeset}
        end
      )
      |> Ecto.Multi.run(
        :sync_id,
        fn _, _ ->
          r =
            CCloud.Repo.get_by(
              CCloud.Repo.SyncIDIsla,
              idHosp: idHosp,
              idIsla: idIsla
            )

          case r do
            nil ->
              {:error, nil}

            _ ->
              {:ok, r.sync_id}
          end
        end
      )
      |> Ecto.Multi.run(
        :insert_or_update,
        fn _, %{changesets: changesets} ->
          Enum.each(
            changesets,
            fn c ->
              CCloud.Repo.insert_or_update(c)
            end
          )

          {:ok, nil}
        end
      )
      |> Ecto.Multi.update(
        :max_sync_id,
        fn q ->
          sync_id_isla = q[:sync_id]
          sync_id = max(sync_id_isla, sync_id_reg)

          Ecto.Changeset.change(
            %CCloud.Repo.SyncIDIsla{
              idHosp: idHosp,
              idIsla: idIsla
            },
            sync_id: sync_id
          )
        end
      )
      |> CCloud.Repo.transaction()

    case status do
      {:ok, result} ->
        sync_id = result[:max_sync_id].sync_id
        sync_id

      _ ->
        :error
    end
  end

  def get(idHosp, _idIsla, table, sector, sync_id, filter) do
    q =
      case idH(table) do
        :idHospital ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospital == ^idHosp,
            select: r
          )

        :idHosp ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHosp == ^idHosp,
            select: r
          )

        :idHospitalCama ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospitalCama == ^idHosp,
            select: r
          )

        :idHospitalLab ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospitalLab == ^idHosp,
            select: r
          )

        :idHospitalRad ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospitalRad == ^idHosp,
            select: r
          )

        :id_hospital ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.id_hospital == ^idHosp,
            select: r
          )
      end

    q =
      if sector == nil do
        q
      else
        case numeroHC(table) do
          :numeroHC ->
            from([registro: r] in q,
              join: c in Hospital.Cama,
              as: :cama,
              on: r.numeroHC == c.numeroHCPac and c.idSector == ^sector
            )

          :numeroHCLab ->
            from([registro: r] in q,
              join: c in Hospital.Cama,
              as: :cama,
              on: r.numeroHCLab == c.numeroHCPac and c.idSector == ^sector
            )

          :numeroHCRad ->
            from([registro: r] in q,
              join: c in Hospital.Cama,
              as: :cama,
              on: r.numeroHCRad == c.numeroHCPac and c.idSector == ^sector
            )

          :numeroHCSignosVitales ->
            from([registro: r] in q,
              join: c in Hospital.Cama,
              as: :cama,
              on:
                r.numeroHCSignosVitales == c.numeroHCPac and
                  c.idSector == ^sector
            )
        end
      end

    q =
      if(filter == nil) do
        q
      else
        filter.(q)
      end

    q =
      from(r in q,
        distinct: true
      )

    result = CCloud.Repo.all(q)

    result = Enum.map(result, fn x -> clean(table, x) end)
    result
  end

  def get_update(idHosp, idIsla, sector, sync_id) do
    list = [
      Isla.SignosVitales,
      Isla.Laboratorio,
      Isla.RxTorax,
      Isla.Alerta,
      Isla.Episodio,
      Isla.HCpaciente
    ]

    result =
      Enum.reduce(list, %{}, fn x, acc ->
        list = get(idHosp, idIsla, x, sector, sync_id, nil)

        Map.put(acc, x.plural, list)
      end)

    result
  end

  def get_sync_id(idHosp, idIsla) do
    r =
      CCloud.Repo.get_by(
        CCloud.Repo.SyncIDIsla,
        idHosp: idHosp,
        idIsla: idIsla
      )

    r.sync_id
  end
end

defmodule Isla.SignosVitales do
  use Ecto.Schema

  def plural, do: :signosVitales

  @primary_key false
  schema "SignosVitales" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:numeroHCSignosVitales, :string, primary_key: true)
    field(:fechaSignosVitales, :integer, primary_key: true)
    field(:auditoria, :string)
    field(:frec_resp, :integer)
    field(:sat_oxi, :integer)
    field(:disnea, :string)
    field(:oxigenoSuplementario, :string)
    field(:fraccionInsOxigeno, :integer)
    field(:presSist, :integer)
    field(:frec_card, :integer)
    field(:temp, :float)
    field(:nivelConciencia, :string)
  end
end

defmodule Isla.Laboratorio do
  use Ecto.Schema

  def plural, do: :laboratorios

  @primary_key false
  schema "Laboratorio" do
    field(:sync_id, :integer)
    field(:idHospitalLab, :string, primary_key: true)
    field(:numeroHCLab, :string, primary_key: true)
    field(:fecha, :integer, primary_key: true)
    field(:cuil, :string)
    field(:dimeroD, :integer)
    field(:linfopenia, :integer)
    field(:plaquetas, :integer)
    field(:ldh, :integer)
    field(:ferritina, :integer)
    field(:proteinaC, :float)
  end
end

defmodule Isla.RxTorax do
  use Ecto.Schema

  def plural, do: :rx_toraxs

  @primary_key false
  schema "RxTorax" do
    field(:sync_id, :integer)
    field(:idHospitalRad, :string, primary_key: true)
    field(:numeroHCRad, :string, primary_key: true)
    field(:fechaRad, :integer, primary_key: true)
    field(:cuil, :string)
    field(:resultadoRad, :string)
  end
end

defmodule Isla.Alerta do
  use Ecto.Schema

  def plural, do: :alertas

  @primary_key false
  schema "Alerta" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:numeroHC, :string, primary_key: true)
    field(:fechaAlerta, :integer, primary_key: true)
    field(:gravedadAlerta, :integer)
    field(:gravedadAnterior, :integer)
    field(:anotacionMedico, :string)
    field(:auditoriaMedico, :string)
  end
end

defmodule Isla.Episodio do
  use Ecto.Schema

  def plural, do: :episodios

  @primary_key false
  schema "Episodio" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:numeroHC, :string, primary_key: true)
    field(:fechaIngreso, :integer, primary_key: true)
    field(:fechaEgreso, :integer)
    field(:razon, :string)
    field(:cuil, :string)
  end
end

defmodule Isla.HCpaciente do
  use Ecto.Schema

  def plural, do: :hcpacientes

  @primary_key false
  schema "HCpaciente" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:idIsla, :string, primary_key: true)
    field(:numeroHC, :string, primary_key: true)
    field(:tipoDocumento, :string)
    field(:paisExp, :string)
    field(:dni, :string)
    field(:nombre, :string)
    field(:apellido, :string)
    field(:nacionalidad, :string)
    field(:genero, :string)
    field(:calle, :string)
    field(:numero, :string)
    field(:piso, :string)
    field(:id_provincia, :integer)
    field(:id_loc, :integer)
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

defmodule Isla.AlertaVista do
  use Ecto.Schema

  def plural, do: :alertas_vistas

  @primary_key false
  schema "AlertaVista" do
    field(:idHospital, :string, primary_key: true)
    field(:numeroHC, :string, primary_key: true)
    field(:fechaAlerta, :integer, primary_key: true)
    field(:cuil, :string, primary_key: true)
  end
end
