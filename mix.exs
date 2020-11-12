defmodule Ccloud.MixProject do
  use Mix.Project

  def project do
    [
      app: :ccloud,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :poison, :mariaex, :ecto],
      mod: {CCloud.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~>2.0"},
      {:ecto_sql, "~> 3.5.3"},
      {:poison, "~> 3.0"},
      {:mariaex, "~> 0.9.1"},
      {:myxql, ">= 0.0.0"}
    ]
  end
end
