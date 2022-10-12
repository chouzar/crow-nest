defmodule CrowNest.MixProject do
  use Mix.Project

  def project do
    [
      app: :crow_nest,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      archives: [mix_gleam: "~> 0.6.0"],
      compilers: [:gleam | Mix.compilers()],
      aliases: [
        "deps.get": ["deps.get", "gleam.deps.get"]
      ],
      erlc_paths: ["build/dev/erlang/crow_nest/build"],
      erlc_include_path: "build/dev/erlang/crow_nest/include"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {CrowNest, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:scenic, "~> 0.11.0-beta.0"},
      {:scenic_driver_local, "~> 0.11.0-beta.0"},
      # {:gleam_stdlib, "~> 0.22"},
      # {:gleam_otp, "~> 0.5"},
      # {:gleeunit, "~> 0.6", only: [:dev, :test], runtime: false}
      {:for_the_crows, "~> 0.0.6"}
    ]
  end
end
