defmodule Ecto.ShortUUID.MixProject do
  use Mix.Project

  @name "Ecto.ShortUUID"
  @app :ecto_shortuuid
  @version "0.4.0"
  @url "https://github.com/gpedic/ecto_shortuuid"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.5",
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
    ]
  end

  defp description do
    """
    Ecto.ShortUUID is a custom Ecto type which adds support for ShortUUID in Ecto schemas

    More info on ShortUUID: https://github.com/gpedic/ex_shortuuid
    """
  end

  defp docs() do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @url,
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ]
    ]
  end

  defp package do
    # These are the default files included in the package
    [
      name: @app,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Goran Pedić"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:benchee, "~> 1.5", only: :dev, runtime: false},
      {:shortuuid, "~> 4.0 or ~> 3.0 or ~> 2.1"},
      {:ecto, "~> 2.2 or ~> 3.0"}
    ]
  end
end
