defmodule Isla do
  use GenServer
  import Utils

  defstruct sync_id: 0,
            id_hospital: nil,
            id_isla: nil,
            alertas: {0, []},
            controles_enfermeria: {0, []},
            episodios: {0, []},
            laboratorios: {0, []},
            rx_toraxs: {0, []}

  def new_control_enfermeria(hospital, isla, control_enfermeria) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:new, :controles_enfermeria, control_enfermeria}
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

  def get_controles_enfermeria(hospital, isla, sync_id) do
    GenServer.call(
      get_name_id(hospital, isla),
      {:get, :controles_enfermeria, sync_id}
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

  def inc_sync_id(id_hospital, isla) do
    GenServer.call(get_name_id(id_hospital, isla), {:inc_sync_id})
  end

  def init(opts) do
    hospital = opts[:id_hospital]
    isla = opts[:id_isla]
    {:ok, %Isla{id_hospital: hospital, id_isla: isla}}
  end

  def start_link(opts) do
    hospital = opts[:id_hospital]
    isla = opts[:id_isla]
    GenServer.start_link(__MODULE__, opts, name: get_name_id(hospital, isla))
  end

  def handle_call({:new, table, registro}, _from, state) do
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

    {triage, nstate} = run_triage(nstate)

    {:reply, {sync_id, triage}, nstate}
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

  def handle_call({:get_update, sync_id}, _from, state) do
    list = [
      :controles_enfermeria,
      :laboratorios,
      :rx_toraxs,
      :alertas,
      :episodios
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
      :controles_enfermeria -> Isla.ControlEnfermeria
      :laboratorios -> Isla.Laboratorio
      :rx_toraxs -> Isla.RXTorax
      :alertas -> Isla.Alerta
      :episodios -> Isla.Episodio
    end
  end
end

defmodule Isla.ControlEnfermeria do
  defstruct [
    :sync_id,
    :id_hospital,
    :nhc,
    :fecha,
    :auditoria,
    :frecuencia_respiratoria,
    :saturacion_de_oxigeno,
    :oxigeno_suplementario,
    :presion_sistolica,
    :frecuencia_cardiaca,
    :temperatura,
    :disnea,
    :nivel_de_conciencia
  ]
end

defmodule Isla.Laboratorio do
  defstruct [
    :sync_id,
    :id_hospital,
    :nhc,
    :fecha,
    :auditoria,
    :dimero_d,
    :linfocitos,
    :plaquetas,
    :ldh,
    :ferritina,
    :proteina_c_reactiva
  ]
end

defmodule Isla.RXTorax do
  defstruct [
    :sync_id,
    :id_hospital,
    :nhc,
    :fecha,
    :auditoria,
    :resultado
  ]
end

defmodule Isla.Alerta do
  defstruct [
    :sync_id,
    :id_hospital,
    :nhc,
    :fecha,
    :gravedad
  ]
end

defmodule Isla.Episodio do
  defstruct [
    :sync_id,
    :id_hospital,
    :nhc,
    :fecha_ingreso,
    :fecha_egreso,
    :razon_egreso,
    :auditoria_egreso
  ]
end
