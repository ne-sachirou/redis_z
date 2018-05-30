defmodule RedisZ.MixProject do
  use Mix.Project

  def project do
    [
      app: :redis_z,
      deps: deps(),
      description: "",
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      elixir: "~> 1.5",
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

  def application do
    [
      extra_applications: [:logger],
      mod: {RedisZ.Application, []}
    ]
  end

  defp deps do
    [
      {:inner_cotton, github: "ne-sachirou/inner_cotton", only: [:dev, :test]}
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
