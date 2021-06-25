defmodule Isla do
  use GenServer
  use Ecto.Schema
  import Ecto.Query
  import Utils

  def new_signo_vital(hospital, isla, signo_vital) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:new, :signosVitales, signo_vital}
    )
  end

  def new_laboratorio(hospital, isla, laboratorio) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:new, :laboratorios, laboratorio}
    )
  end

  def new_rx_torax(hospital, isla, rx_torax) do
    GenServer.call(get_name_id(hospital, isla), {:new, :rx_toraxs, rx_torax})
  end

  def new_alerta(hospital, isla, alerta) do
    GenServer.call(get_name_id(hospital, isla), {:new, :alertas, alerta})
  end

  def new_episodio(hospital, isla, episodio) do
    GenServer.call(get_name_id(hospital, isla), {:new, :episodios, episodio})
  end

  def new_hcpaciente(hospital, isla, hcpaciente) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:new, :hcpacientes, hcpaciente}
    )
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
    GenServer.call(
      get_name_id(hospital, isla),
      {:modify, :signosVitales, signo_vital}
    )
  end

  def modify_laboratorio(hospital, isla, laboratorio) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:modify, :laboratorios, laboratorio}
    )
  end

  def modify_rx_torax(hospital, isla, rx_torax) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:modify, :rx_toraxs, rx_torax}
    )
  end

  def modify_alerta(hospital, isla, alerta) do
    GenServer.call(get_name_id(hospital, isla), {:modify, :alertas, alerta})
  end

  def modify_episodio(hospital, isla, episodio) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:modify, :episodios, episodio}
    )
  end

  def modify_hcpaciente(hospital, isla, hcpaciente) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:modify, :hcpacientes, hcpaciente}
    )
  end

  def copy_signo_vital(hospital, isla, signo_vital) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:copy, :signosVitales, signo_vital}
    )
  end

  def copy_laboratorio(hospital, isla, laboratorio) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:copy, :laboratorios, laboratorio}
    )
  end

  def copy_rx_torax(hospital, isla, rx_torax) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:copy, :rx_toraxs, rx_torax}
    )
  end

  def copy_alerta(hospital, isla, alerta) do
    GenServer.call(get_name_id(hospital, isla), {:copy, :alertas, alerta})
  end

  def copy_episodio(hospital, isla, episodio) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:copy, :episodios, episodio}
    )
  end

  def copy_hcpaciente(hospital, isla, hcpaciente) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:copy, :hcpacientes, hcpaciente}
    )
  end

  def get_signos_vitales(hospital, isla, sector, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :signosVitales, sector, sync_id, nil}
    )
  end

  def get_laboratorios(hospital, isla, sector, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :laboratorios, sector, sync_id, nil}
    )
  end

  def get_rx_toraxs(hospital, isla, sector, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :rx_toraxs, sector, sync_id, nil}
    )
  end

  def get_alertas(hospital, isla, sector, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :alertas, sector, sync_id, nil}
    )
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
        where: v.cuil == ^cuil
      )
    end

    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :alertas, sector, sync_id, filter}
    )
  end

  def get_episodios(hospital, isla, sector, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :episodios, sector, sync_id, nil}
    )
  end

  def get_hcpacientes(hospital, isla, sector, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :hcpacientes, sector, sync_id, nil}
    )
  end

  def get_update(hospital, isla, sector, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get_update, sector, sync_id}
    )
  end

  def get_sync_id(hospital, isla) do
    GenServer.call(get_name_id(hospital, isla), {:get_sync_id})
  end

  def init(opts) do
    state = %{
      sync_id: opts[:sync_id],
      idIsla: opts[:idIsla],
      idHosp: opts[:idHospital]
    }

    IO.inspect(state.idIsla)

    {:ok, state}
  end

  def start_link(opts) do
    hospital = opts[:idHospital]
    isla = opts[:idIsla]
    GenServer.start_link(__MODULE__, opts, name: get_name_id(hospital, isla))
  end

  def handle_call({:new, table, registro}, _from, state) do
    table = table2module(table)
    registro = cast_all(table, registro)

    sync_id =
      if registro[:sync_id] == nil do
        state.sync_id + 1
      else
        registro.sync_id
      end

    registro = Map.put(registro, :sync_id, sync_id)

    registro = struct(table, registro)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:registro, registro)
    |> Ecto.Multi.update(
      :max_sync_id,
      Ecto.Changeset.change(
        %CCloud.Repo.SyncIDIsla{
          idHosp: state.idHosp,
          idIsla: state.idIsla
        },
        sync_id: sync_id
      )
    )
    |> CCloud.Repo.transaction()

    nstate = Map.put(state, :sync_id, sync_id)

    {triage, nstate} = run_triage(nstate)

    {:reply, {sync_id, triage}, nstate}
  end

  def handle_call({:modify, table, registro}, _from, state) do
    table = table2module(table)
    registro = cast_all(table, registro)

    sync_id =
      if registro[:sync_id] == nil do
        state.sync_id + 1
      else
        registro.sync_id
      end

    registro = Map.put(registro, :sync_id, sync_id)

    keys =
      Map.take(
        registro,
        Keyword.keys(Ecto.primary_key(struct(table, registro)))
      )

    keys = struct(table, keys)

    registro = Ecto.Changeset.change(keys, registro)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:registro, registro)
    |> Ecto.Multi.update(
      :max_sync_id,
      Ecto.Changeset.change(
        %CCloud.Repo.SyncIDIsla{
          idHosp: state.idHosp,
          idIsla: state.idIsla
        },
        sync_id: sync_id
      )
    )
    |> CCloud.Repo.transaction()

    nstate = Map.put(state, :sync_id, sync_id)

    {triage, nstate} = run_triage(nstate)

    {:reply, {sync_id, triage}, nstate}
  end

  def handle_call({:copy, table, registro}, _from, state) do
    table = table2module(table)
    registro = cast_all(table, registro)

    sync_id = Enum.max([registro.sync_id, state.sync_id])

    keys =
      Map.take(
        registro,
        Keyword.keys(Ecto.primary_key(struct(table, registro)))
      )
      |> Map.to_list()

    changeset =
      case CCloud.Repo.get_by(table, keys) do
        nil -> struct(table, keys)
        reg -> reg
      end
      |> Ecto.Changeset.change(registro)

    Ecto.Multi.new()
    |> Ecto.Multi.insert_or_update(:registro, changeset)
    |> Ecto.Multi.update(
      :max_sync_id,
      Ecto.Changeset.change(
        %CCloud.Repo.SyncIDIsla{
          idHosp: state.idHosp,
          idIsla: state.idIsla
        },
        sync_id: sync_id
      )
    )
    |> CCloud.Repo.transaction()

    nstate = Map.put(state, :sync_id, sync_id)

    {:reply, sync_id, nstate}
  end

  def handle_call({:get, table, sector, sync_id, filter}, _from, state) do
    table = table2module(table)

    q =
      case idH(table) do
        :idHospital ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospital == ^state.idHosp,
            select: r
          )

        :idHosp ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHosp == ^state.idHosp,
            select: r
          )

        :idHospitalCama ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospitalCama == ^state.idHosp,
            select: r
          )

        :idHospitalLab ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospitalLab == ^state.idHosp,
            select: r
          )

        :idHospitalRad ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.idHospitalRad == ^state.idHosp,
            select: r
          )

        :id_hospital ->
          from(r in table,
            as: :registro,
            where:
              r.sync_id >= ^sync_id and
                r.id_hospital == ^state.idHosp,
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

    result = CCloud.Repo.all(q)

    result = Enum.map(result, fn x -> clean(table, x) end)
    {:reply, result, state}
  end

  def handle_call({:get_update, sector, sync_id}, _from, state) do
    list = [
      :signosVitales,
      :laboratorios,
      :rx_toraxs,
      :alertas,
      :episodios,
      :hcpacientes
    ]

    result =
      Enum.reduce(list, %{}, fn x, acc ->
        {_, list, _} =
          handle_call({:get, x, sector, sync_id, nil}, self(), state)

        Map.put(acc, x, list)
      end)

    {:reply, result, state}
  end

  def handle_call({:get_sync_id}, _from, state) do
    {:reply, state.sync_id, state}
  end

  defp run_triage(state) do
    # TODO
    {0, state}
  end
end

defmodule Isla.SignosVitales do
  use Ecto.Schema

  @primary_key false
  schema "SignosVitales" do
    field(:sync_id, :integer)
    field(:id_hospital, :string, primary_key: true)
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

  @primary_key false
  schema "AlertaVista" do
    field(:idHospital, :string, primary_key: true)
    field(:numeroHC, :string, primary_key: true)
    field(:fechaAlerta, :integer, primary_key: true)
    field(:cuil, :string, primary_key: true)
  end
end
