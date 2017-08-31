defmodule Sandbox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sandbox,
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
    [
      {:ex_doc,         "~> 0.16.1", only: :dev},
      {:mix_test_watch, "~> 0.4.1",  only: :dev},
      {:dialyxir,       "~> 0.5.1",  only: :dev}
    ]
  end
end
