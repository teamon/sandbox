# test run - put config
# (this needs to be at the very top to be available at compile time)
Application.put_env(:myapp, MyApp.Events, handlers: [
  MyApp.Indexer,
  MyApp.SlackNotifications,
  MyApp.Marketing
])


defmodule MyApp.Events do
  use Ev, otp_app: :myapp


  # Define events with all their parameters & types
  defev TeamInstalled,  team_id:    Ecto.UUID.t,
                        team_name:  String.t

  defev OrderClosed,    team_id:  Ecto.UUID.t,
                        order_id: Ecto.UUID.t,
                        value:    integer

  # Event handlers are configured via standard
  # otp config like this:
  #
  # # config/dev.exs
  # config :myapp, MyApp.Events, handlers: [
  #   MyApp.Indexer
  # ]
  #
  # # config/prod.exs
  # config :myapp, MyApp.Events, handlers: [
  #   MyApp.Indexer,
  #   MyApp.SlackNotifications,
  #   MyApp.Marketing
  # ]
  #
  # # config/test.exs
  # config :myapp, MyApp.Events, handlers: [
  #   MyApp.TestHandler
  # ]
end


# events handlers
defmodule MyApp.SlackNotifications do
  @behaviour Ev.Handler

  alias MyApp.Events

  def handle(%Events.TeamInstalled{} = ev) do
    IO.puts "SLACK: team installed #{ev.team_name}"
  end

  def handle(%Events.OrderClosed{} = ev) do
    IO.puts "SLACK: order closed #{ev.team_id}"
  end

  def handle(_), do: :ok
end

defmodule MyApp.Marketing do
  @behaviour Ev.Handler

  alias MyApp.Events

  def handle(%Events.TeamInstalled{} = ev) do
    IO.puts "MARKETING: sending email to #{ev.team_name}"
  end

  def handle(_), do: :ok
end

defmodule MyApp.Indexer do
  @behaviour Ev.Handler

  alias MyApp.Events

  def handle(%Events.TeamInstalled{} = ev) do
    IO.puts "MARKETING: indexing team #{ev.team_id}"
  end

  def handle(_), do: :ok
end


# regular action module
defmodule MyApp.Actions do
  alias MyApp.Events

  def install_team(name) do
    # ... do core logic ...
    Events.publish %Events.TeamInstalled{team_id: "T123", team_name: name}
  end

  def close_order(id, value) do
    # ... do core logic ...
    Events.publish_async %Events.OrderClosed{team_id: "T123", order_id: id, value: value}
  end
end


# call some action
MyApp.Actions.install_team("Noodle")
MyApp.Actions.install_team("ACME")
MyApp.Actions.close_order("XYZ", 100)
