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

  def table2module(table) do
    case table do
      :usuarios_hospital -> Hospital.UsuarioHospital
      :islas -> Hospital.Isla
      :sectores -> Hospital.Sector
      :usuarios_sector -> Hospital.UsuarioSector
      :camas -> Hospital.Cama
      :hospitales -> Hospital
      :signosVitales -> Isla.SignosVitales
      :laboratorios -> Isla.Laboratorio
      :rx_toraxs -> Isla.RxTorax
      :alertas -> Isla.Alerta
      :episodios -> Isla.Episodio
      :hcpacientes -> Isla.HCpaciente
    end
  end

  def idH(table) do
    case table do
      :alertas -> :idHospital
      :camas -> :idHospitalCama
      :episodios -> :idHospital
      :hcpacientes -> :idHospital
      :hospitales -> :idHosp
      :islas -> :idHospital
      :laboratorios -> :idHospitalLab
      :rx_toraxs -> :idHospitalRad
      :sectores -> :idHospital
      :signosVitales -> :id_hospital
      :usuarios_hospital -> :idHospital
      :usuarios_sector -> :idHospital
    end
  end

  def numeroHC(table) do
    case table do
      :alertas -> :numeroHC
      :camas -> :numeroHCPac
      :episodios -> :numeroHC
      :hcpacientes -> :numeroHC
      :laboratorios -> :numeroHCLab
      :rx_toraxs -> :numeroHCRad
      :signosVitales -> :numeroHCSignosVitales
    end
  end

  @doc """
  Cleans module register of all improper keys
  """
  @spec clean(Module, Map) :: String.t()
  def clean(module, reg) do
    proper_keys =
      Map.keys(struct(module, %{}))
      |> List.delete(:__meta__)
      |> List.delete(:__struct__)

    reg = Map.take(reg, proper_keys)
    reg
  end

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
