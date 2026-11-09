defmodule Ecto.ShortUUID.MixProject do
  use Mix.Project

  @name "Ecto.ShortUUID"
  @app :ecto_shortuuid
  @version "0.4.1"
  @url "https://github.com/gpedic/ecto_shortuuid"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts"
      ],
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
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG.md"],
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

  # `mix ci` runs every check CI runs. The analysis tools are dev-only (some
  # of their deps need newer Elixir versions than this library supports), so
  # the alias runs in dev and starts the test suite in a separate test-env Mix.
  defp aliases do
    [
      ci: [
        "deps.unlock --check-unused",
        "hex.audit",
        "deps.audit",
        "format --check-formatted",
        "compile --warnings-as-errors --force",
        "credo --strict",
        "sobelow --exit low --private",
        "dialyzer",
        &test_in_test_env/1
      ]
    ]
  end

  defp test_in_test_env(_args) do
    status =
      Mix.shell().cmd(
        "mix do compile --warnings-as-errors --force + test --warnings-as-errors",
        env: [{"MIX_ENV", "test"}]
      )

    if status != 0, do: Mix.raise("mix test failed")
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:benchee, "~> 1.5", only: :dev, runtime: false},
      {:stream_data, "~> 1.1", only: [:dev, :test]},
      {:sobelow, "~> 0.18", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: :dev, runtime: false},
      {:shortuuid, "~> 4.2"},
      {:ecto, ecto_requirement()}
    ]
  end

  # CI sets ECTO_VERSION (e.g. "== 3.10.0") to run the suite against the
  # oldest supported Ecto release instead of the locked one.
  defp ecto_requirement do
    case System.get_env("ECTO_VERSION") do
      version when version in [nil, ""] -> "~> 3.10"
      version -> version
    end
  end
end
