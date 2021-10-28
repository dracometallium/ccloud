defmodule Hospitales do
  import Ecto.Query
  import UUIDgen

  def get_usuarios() do
    usuarios =
      CCloud.Repo.all(from(r in Hospitales.Usuario, select: r))
      |> Enum.map(fn x ->
        x
        |> Map.delete(:__meta__)
        |> Map.delete(:__struct__)
      end)

    usuarios
  end

  def new_hospital(hospital) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:registro, struct(Hospital, hospital))
    |> Ecto.Multi.insert(:sync_id_isla, %CCloud.Repo.SyncIDHosp{
      idHosp: hospital.idHosp,
      sync_id: 0
    })
    |> CCloud.Repo.transaction()

    0
  end

  def new_usuario(usuario) do
    sal = uuidgen()

    salted =
      :crypto.hash(:sha512, usuario.clave <> sal)
      |> Base.encode16(case: :lower)

    usuario = Map.put(usuario, :sal, sal)
    usuario = Map.put(usuario, :clave, salted)
    CCloud.Repo.insert(struct(Hospitales.Usuario, usuario))
    usuario
  end

  def get_datos_usuario(cuil) do
    usuario =
      CCloud.Repo.one(
        from(r in Hospitales.Usuario,
          where: r.cuil == ^cuil,
          select: r
        )
      )
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)

    roles =
      CCloud.Repo.all(
        from(r in Hospital.UsuarioHospital,
          where: r.cuil == ^cuil,
          select: [:idHospital, :idRol]
        )
      )
      |> Enum.reduce(%{}, fn %{idHospital: idHospital, idRol: idRol}, acc ->
        if acc[idHospital] == nil do
          Map.put(acc, idHospital, [idRol])
        else
          roles = acc[idHospital]
          Map.put(acc, idHospital, [idRol | roles])
        end
      end)

    q =
      from(u in Hospital.UsuarioSector,
        as: :usuario,
        where: u.cuil == ^cuil
      )

    q =
      from([usuario: u] in q,
        join: h in Hospital,
        as: :hospital,
        on: h.idHosp == u.idHospital
      )

    q =
      from([usuario: u, hospital: h] in q,
        join: s in Hospital.Sector,
        as: :sector,
        on: u.idSector == s.idSector,
        select: [s.idHospital, h.nombre, s.idSector, s.descripcion]
      )

    sectores =
      CCloud.Repo.all(q)
      |> Enum.reduce(%{}, fn [
                               idHospital,
                               nombreHosp,
                               idSector,
                               descSector
                             ],
                             acc ->
        cond do
          acc[idHospital] == nil ->
            sectores = [%{idSector: idSector, descripcion: descSector}]
            hospital = Map.put(%{nombre: nombreHosp}, :sectores, sectores)
            Map.put(acc, idHospital, hospital)

          true ->
            sectores = [
              %{idSector: idSector, descripcion: descSector}
              | acc[idHospital]
            ]

            hospital = Map.put(acc[idHospital], :sectores, sectores)
            Map.put(acc, idHospital, hospital)
        end
      end)

    hospitales =
      Map.keys(sectores)
      |> Enum.concat(Map.keys(roles))
      |> Enum.uniq()

    hospitales =
      Enum.reduce(hospitales, [], fn idHospital, acc ->
        [
          %{
            idHospital: idHospital,
            nombre: sectores[idHospital][:nombre],
            sectores: sectores[idHospital][:sectores],
            roles: roles[idHospital]
          }
          | acc
        ]
      end)

    respuesta = %{usuario: usuario, hospitales: hospitales}

    respuesta
  end
end

defmodule Hospitales.Usuario do
  use Ecto.Schema

  @primary_key false
  schema "Usuario" do
    field(:cuil, :string, primary_key: true)
    field(:clave, :string)
    field(:sal, :string)
    field(:nombre, :string)
    field(:apellido, :string)
    field(:email, :string)
    field(:telefono, :string)
  end
end
