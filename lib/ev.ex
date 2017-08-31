defmodule Ev do
  @moduledoc """
  Very simple sync/async event sourcing library.
  The main purpose is to integrate some event sourcing
  into existing codebase with little to no everhead.
  It does not use any external event bus, everything happens
  in the same Beam VM with simple function calls (sync)
  or message passing (async).

  You need two things to integrate this library:
    1. Event definitions
    2. Event handlers

  ## Event definitions

  Create a module (e.g. `MyApp.Events`), include `use Ev`
  passing you OTP app name (more on that later) and
  define you events. Under the hood each event is
  an Exliri struct with enforced keys and typespec.

      defmodule MyApp.Events do
        use Ev, otp_app: :myapp

        # Define events with defev(Name, Attr: Type)

        defev UserSignedUp, user_id:    pos_integer,
                            user_name:  String.t

        defev OrderPlaced,  order_id: pos_integer,
                            user_id:  pos_integer,
                            value:    non_neg_integer
      end


  ## Event handlers

  Event handlers are modules with a single `handle(event)`
  callback function. You can create as many event handlers
  as you want to.

      defmodule MyApp.SlackNotifications do
        @behaviour Ev.Handler

        alias MyApp.Events

        def handle(%Events.UserSignedUp{} = ev) do
          IO.puts "SLACK: New user signed up! \#{ev.user_name}"
        end

        def handle(%Events.OrderPlaced{} = ev) do
          IO.puts "SLACK: New order placed \#{ev.value}"
        end

        # catch-all clause
        def handle(_), do: :ok
      end


  ## Configuration

  To configure event handlers for different environments
  use standard mix project configuration. With this
  approach it is trivial to exclude sending emails
  or notifications in dev/test.

      # config/dev.exs
      config :myapp, MyApp.Events, handlers: [
        MyApp.Indexer
      ]

      # config/prod.exs
      config :myapp, MyApp.Events, handlers: [
        MyApp.Indexer,
        MyApp.SlackNotifications,
        MyApp.MarketingEmails
      ]

      # config/test.exs
      config :myapp, MyApp.Events, handlers: [
        MyApp.TestHandler
      ]


  ## Publishing events

  Use `MyApp.Events.publish_sync/1` or `publish_async/1` to

  """

  defmodule Handler do
    @moduledoc """
    Example

        defmodule MyApp.SlackNotifications do
          @behaviour Ev.Handler

          alias MyApp.Events

          def handle(%Events.UserSignedUp{} = ev) do
            IO.puts "SLACK: New user signed up! \#{ev.user_name}"
          end

          def handle(%Events.OrderPlaced{} = ev) do
            IO.puts "SLACK: New order placed \#{ev.value}"
          end

          # catch-all clause
          def handle(_), do: :ok
        end
    """
    @callback handle(any) :: no_return
  end

  @doc """
  Define your events module

  Example:

      defmodule MyApp.Events do
        use Ev, otp_app: :myapp

        defev UserSignedUp, user_id: pos_integer, user_name: String.t
        defev OrderPlaced, order_id: pos_integer, value: non_neg_integer
      end
  """
  defmacro __using__(opts \\ []) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      import Ev, only: [defev: 1, defev: 2]
      @_ev_config   Application.fetch_env!(unquote(otp_app), __MODULE__)
      @_ev_handlers Keyword.fetch!(@_ev_config, :handlers)

      def publish_sync(event),  do: Ev.publish_sync(event, @_ev_handlers)
      def publish_async(event), do: Ev.publish_async(event, @_ev_handlers)

      # alias publish to publish_sync
      def publish(event), do: publish_sync(event)
    end
  end

  @doc """
  Define module with struct and typespec, in single line

  Example:
      use Ev
      defev User, id:   integer,
                  name: String.t
  is the same as
      defmodule User do
        @type t :: %__MODULE__{
          id:   integer,
          name: String.t
        }
        @enforce_keys [:id, :name]
        defstruct [:id, :name]
      end
  """
  defmacro defev(name, attrs \\ []) do
    keys = Keyword.keys(attrs)

    quote do
      defmodule unquote(name) do
        @enforce_keys unquote(keys)
        defstruct @enforce_keys
        @type t :: %__MODULE__{
          unquote_splicing(attrs)
        }
      end
    end
  end

  @doc """
  Publish event to handers synchronously
  """
  def publish_sync(event, handlers) do
    for handler <- handlers do
      apply(handler, :handle, [event])
    end

    :ok
  end

  @doc """
  Publish event to handlers asynchronously.
  Each handler will be run in a separate process.
  """
  def publish_async(event, handlers) do
    for handler <- handlers do
      spawn handler, :handle, [event]
    end

    :ok
  end
end
