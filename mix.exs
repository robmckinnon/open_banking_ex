defmodule OpenBanking.MixProject do
  use Mix.Project

  def project do
    [
      app: :open_banking,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:json_web_token, "~> 0.2"},
      # {:joken, git: "https://github.com/bryanjos/joken.git", tag: "v2.0.0-rc2"},
      {:joken, "~> 2.0.1"},
      {:httpoison, "~> 1.5.0"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:mock, "~> 0.3.3", only: :test},
      {:poison, "~> 3.1"},
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end
