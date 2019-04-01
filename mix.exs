defmodule OpenBanking.MixProject do
  use Mix.Project

  def project do
    [
      app: :open_banking_ex,
      version: "0.1.0",
      elixir: "~> 1.6 or ~> 1.7 or ~> 1.8",
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
      {:joken, "~> 2.0.1"},
      {:httpoison, "~> 1.5.0"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.3", only: :test},
      {:poison, "~> 3.1"},
      {:elixir_uuid, "~> 1.2"},
      # Doc dependencies
      {:ex_doc, "~> 0.19", only: :docs, runtime: false},
      {:inch_ex, "~> 2.0", only: :docs, runtime: false}
    ]
  end
end
