defmodule UUIDgen do
  @moduledoc """
  # Documentation for `UUIDgen`.
  Uses the system `uuidgen` command to generate UUIDs.

  USE:
  -  uuidgen(): returns a uuid as a string.
  -  uuidgen(n): returns a list of uuids, each as a string.
  """

  @doc @moduledoc

  def uuidgen() do
    System.cmd("uuidgen", [])
    |> elem(0)
    |> String.trim()
  end

  defp uuidgen_p(1, uuid_list) do
    [uuidgen() | uuid_list]
  end

  defp uuidgen_p(n, uuid_list) do
    uuidgen_p(n - 1, [uuidgen() | uuid_list])
  end

  def uuidgen(n) do
    if n > 0 do
      uuidgen_p(n, [])
    else
      []
    end
  end
end
