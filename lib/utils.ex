defmodule Utils do
  def get_name_id(hospital, isla) do
    {:global, {:id, hospital, isla}}
  end

  def get_name_id(hospital) do
    {:global, {:id, hospital}}
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
end
