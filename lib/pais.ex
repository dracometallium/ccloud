defmodule Pais do
  import Ecto.Query

  @moduledoc """
  # Documentation for `Pais`.
  Permite acceder a todas las provincias y localidades de un país. La base de
  datos distingue el país por el TLD (sin el punto, solo 2 caracteres).

  USE:
  - get_provincias(pais): retorna una lista de las provincias ([%{:id_provincia,
    :nombre}]) del país.
  - get_localidades(pais, provincia): retorna una lista de las localidades
    ([%{:id_loc, :nombre}]) de la provincia.
  """

  def get_provincias(pais) do
    CCloud.Repo.all(
      from(r in Pais.Provincia,
        where: r.pais == ^pais,
        select: [:id_provincia, :nombre]
      )
    )
    |> Enum.map(fn x ->
      x
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)
      |> Map.delete(:pais)
    end)
  end

  def get_localidades(pais, provincia) do
    CCloud.Repo.all(
      from(r in Pais.Localidad,
        where:
          r.pais == ^pais and
            r.id_provincia == ^provincia,
        select: [:id_loc, :nombre]
      )
    )
    |> Enum.map(fn x ->
      x
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)
      |> Map.delete(:pais)
      |> Map.delete(:id_provincia)
    end)
  end
end

defmodule Pais.Provincia do
  use Ecto.Schema

  @primary_key false
  schema "Provincia" do
    field(:pais, :string, primary_key: true)
    field(:id_provincia, :integer, primary_key: true)
    field(:nombre, :string)
  end
end

defmodule Pais.Localidad do
  use Ecto.Schema

  @primary_key false
  schema "Localidad" do
    field(:pais, :string, primary_key: true)
    field(:id_provincia, :integer, primary_key: true)
    field(:id_loc, :integer, primary_key: true)
    field(:nombre, :string)
  end
end
