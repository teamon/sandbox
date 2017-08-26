defmodule Ok.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ok,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:mix_test_watch, "~> 0.4.1", only: :dev}]
  end
end
