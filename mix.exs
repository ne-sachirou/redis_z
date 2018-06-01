defmodule RedisZ.MixProject do
  use Mix.Project

  def project do
    [
      app: :redis_z,
      deps: deps(),
      description: "Redis Super: Full featured Redis adapter for Elixir based on Redix",
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      elixir: "~> 1.6",
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: "0.1.0",

      # Docs
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      homepage_url: "https://github.com/ne-sachirou/redis_z",
      name: "RedisZ",
      source_url: "https://github.com/ne-sachirou/redis_z"
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:inner_cotton, github: "ne-sachirou/inner_cotton", only: [:dev, :test]},
      {:redix, "~> 0.6"}
    ]
  end

  def package do
    [
      files: ["LICENSE", "README.md", "mix.exs", "lib"],
      licenses: ["GPL-3.0-or-later"],
      links: %{
        GitHub: "https://github.com/ne-sachirou/redis_z"
      },
      maintainers: ["ne_Sachirou <utakata.c4se@gmail.com>"],
      name: :redis_z
    ]
  end
end
