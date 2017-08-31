Application.put_env :sandbox, EvTest.Events, handlers: [
  EvTest.TestHandler
]

defmodule EvTest do
  use ExUnit.Case

  defmodule Events do
    use Ev, otp_app: :sandbox

    defev UserSignedUp, user_id:    pos_integer,
                        user_name:  String.t

    defev OrderPlaced,  order_id: pos_integer,
                        user_id:  pos_integer,
                        value:    non_neg_integer
  end

  defmodule TestHandler do
    alias Events

    def handle(%Events.UserSignedUp{} = ev) do
      send :exunit_current_test, {:test_handler, ev.user_id}
    end

    def handle(_), do: :ok
  end

  setup do
    Process.register(self(), :exunit_current_test)
    :ok
  end

  test "handle subscribed event" do
    Events.publish_sync %Events.UserSignedUp{user_id: 1, user_name: "Jon"}

    assert_receive {:test_handler, 1}
  end

  test "safely ignore not-subscribed event" do
    Events.publish_sync %Events.OrderPlaced{order_id: 1, user_id: 2, value: 100}

    refute_receive {:test_handler, 1}
  end
end
