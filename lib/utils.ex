defmodule Utils do
  @moduledoc """
  Module with shared fuctions that nobody wants.
  """

  def get_name_id(hospital, isla) do
    {:global, {:id, hospital, isla}}
  end

  def get_name_id(hospital) do
    {:global, {:id, hospital}}
  end

  def idH(table) do
    case table do
      Isla.Alerta -> :idHospital
      Hospital.Cama -> :idHospitalCama
      Isla.Episodio -> :idHospital
      Isla.HCpaciente -> :idHospital
      Hospital -> :idHosp
      Hospital.Isla -> :idHospital
      Isla.Laboratorio -> :idHospitalLab
      Isla.RxTorax -> :idHospitalRad
      Hospital.Sector -> :idHospital
      Isla.SignosVitales -> :idHospital
      Hospital.UsuarioHospital -> :idHospital
      Hospital.UsuarioSector -> :idHospital
    end
  end

  def numeroHC(table) do
    case table do
      Isla.Alerta -> :numeroHC
      Hospital.Cama -> :numeroHCPac
      Isla.Episodio -> :numeroHC
      Isla.HCpaciente -> :numeroHC
      Isla.Laboratorio -> :numeroHCLab
      Isla.RxTorax -> :numeroHCRad
      Isla.SignosVitales -> :numeroHCSignosVitales
    end
  end

  @doc """
  Returns a keyword list of the primary keys of the module.
  """
  @spec keys(Module, Map) :: List
  def keys(module, reg) do
    Map.take(
      reg,
      Keyword.keys(Ecto.primary_key(struct(module, reg)))
    )
    |> Map.to_list()
  end

  @doc """
  Cleans a module register of all improper keys.
  """
  @spec clean(Module, Map) :: Map
  def clean(module, reg) do
    proper_keys =
      Map.keys(struct(module, %{}))
      |> List.delete(:__meta__)
      |> List.delete(:__struct__)

    reg = Map.take(reg, proper_keys)
    reg
  end

  @doc """
  Cleans a module register of all improper keys and cast all keys to its
  correct type.
  """
  @spec cast_all(Module, Map) :: Map
  def cast_all(module, reg) do
    reg = clean(module, reg)

    reg =
      Enum.reduce(reg, %{}, fn {k, v}, acc ->
        type = module.__schema__(:type, k)

        case Ecto.Type.cast(type, v) do
          {:ok, nv} -> Map.put(acc, k, nv)
          _ -> Map.put(acc, k, nil)
        end
      end)

    reg
  end
end
