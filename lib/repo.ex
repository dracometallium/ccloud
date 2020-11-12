defmodule CCloud.Repo do
  use Ecto.Repo, otp_app: :ccloud, adapter: Ecto.Adapters.MyXQL
end

defmodule CCloud.Repo.SyncIDHosp do
  use Ecto.Schema

  @primary_key false
  schema "SyncIDHosp" do
    field(:idHosp, :string, primary_key: true)
    field(:sync_id, :integer)
  end
end

defmodule CCloud.Repo.SyncIDIsla do
  use Ecto.Schema

  @primary_key false
  schema "SyncIDIsla" do
    field(:idHosp, :string, primary_key: true)
    field(:idIsla, :string, primary_key: true)
    field(:sync_id, :integer)
  end
end
