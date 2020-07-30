defmodule Utils do
  def get_name_id(hospital, isla) do
    {:global, {:id, hospital, isla}}
  end

  def get_name_id(hospital) do
    {:global, {:id, hospital}}
  end

  def filter_syncid(registros, sync_id) do
    filter_syncid(registros, sync_id, [])
  end

  defp filter_syncid([], _n, result) do
    result
  end

  defp filter_syncid([head | tail], sync_id, result) do
    if head.sync_id < sync_id do
      result
    else
      filter_syncid(tail, sync_id, [head | result])
    end
  end
end