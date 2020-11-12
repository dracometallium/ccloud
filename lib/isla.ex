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

  def get_signos_vitales(hospital, isla, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :signosVitales, sync_id}
    )
  end

  def get_laboratorios(hospital, isla, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :laboratorios, sync_id}
    )
  end

  def get_rx_toraxs(hospital, isla, sync_id) do
    GenServer.call(get_name_id(hospital, isla), {:get, :rx_toraxs, sync_id})
  end

  def get_alertas(hospital, isla, sync_id) do
    GenServer.call(get_name_id(hospital, isla), {:get, :alertas, sync_id})
  end

  def get_episodios(hospital, isla, sync_id) do
    GenServer.call(get_name_id(hospital, isla), {:get, :episodios, sync_id})
  end

  def get_update(hospital, isla, sync_id) do
    GenServer.call(get_name_id(hospital, isla), {:get_update, sync_id})
  end

  def inc_sync_id(idHospital, isla) do
    GenServer.call(get_name_id(idHospital, isla), {:inc_sync_id})
  end

  def init(opts) do
    state = %{
      sync_id: opts[:sync_id],
      idIsla: opts[:idIsla],
      idHosp: opts[:idHospital]
    }

    {:ok, state}
  end

  def start_link(opts) do
    hospital = opts[:idHospital]
    isla = opts[:idIsla]
    GenServer.start_link(__MODULE__, opts, name: get_name_id(hospital, isla))
  end

  def handle_call({:new, table, registro}, _from, state) do
    sync_id =
      if registro[:sync_id] == nil do
        state.sync_id + 1
      else
        registro.sync_id
      end

    Map.put(registro, :sync_id, sync_id)
    registro = struct(table2module(table), registro)
    CCloud.Repo.insert(registro)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:registro, registro)
    |> Ecto.Multi.update(
      :max_sync_id,
      Ecto.Changeset.change(
        %CCloud.Repo.SyncIDIsla{
          idHosp: registro.idHospital,
          idIsla: registro.idIsla
        },
        sync_id: sync_id
      )
    )
    |> CCloud.Repo.transaction()

    nstate = Map.put(state, :sync_id, sync_id)

    {triage, nstate} = run_triage(nstate)

    {:reply, {sync_id, triage}, nstate}
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

  def handle_call({:get_update, sync_id}, _from, state) do
    list = [
      :signosVitales,
      :laboratorios,
      :rx_toraxs,
      :alertas,
      :episodios,
      :isla
    ]

    result = get_fromlist(list, sync_id, state)
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

  defp run_triage(state) do
    # TODO
    {0, state}
  end

  defp table2module(table) do
    case table do
      :signosVitales -> Isla.SignoVital
      :laboratorios -> Isla.Laboratorio
      :rx_toraxs -> Isla.RXTorax
      :alertas -> Isla.Alerta
      :episodios -> Isla.Episodio
    end
  end
end

defmodule Isla.SignoVital do
  use Ecto.Schema

  @primary_key false
  schema "SignoVital" do
    field(:sync_id, :integer)
    field(:id_hospital, :string, primary_key: true)
    field(:numeroHCSignosVitales, :integer, primary_key: true)
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
    field(:numeroHCLab, :integer, primary_key: true)
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

defmodule Isla.RXTorax do
  use Ecto.Schema

  @primary_key false
  schema "RXTorax" do
    field(:sync_id, :integer)
    field(:idHospitalRad, :string, primary_key: true)
    field(:numeroHCRad, :integer, primary_key: true)
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
    field(:numeroHC, :integer, primary_key: true)
    field(:fechaAlerta, :integer, primary_key: true)
    field(:gravedadAlerta, :integer)
    field(:gravedadAnterior, :integer)
    field(:get_laboratorios, :string)
    field(:anotacionEnfermero, :string)
    field(:auditoriaEnfermero, :string)
    field(:calificacionMedico, :string)
    field(:anotacionMedico, :string)
    field(:auditoriaMedico, :string)
    field(:ocultarAlerta, :integer)
  end
end

defmodule Isla.Episodio do
  use Ecto.Schema

  @primary_key false
  schema "Episodio" do
    field(:sync_id, :integer)
    field(:idHospital, :string, primary_key: true)
    field(:numeroHC, :integer, primary_key: true)
    field(:fechaIngreso, :integer, primary_key: true)
    field(:fechaEgreso, :integer)
    field(:razonEgreso, :string)
    field(:cuil, :string)
  end
end
