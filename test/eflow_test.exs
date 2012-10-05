Code.require_file "../test_helper.exs", __FILE__

defmodule SimpleMachine do

  defmacro __using__(opts) do
    quote do
      import SimpleMachine
      use Eflow.Machine, unquote(opts)

      def available?(state) do
        {true, state}
      end
      defoverridable available?: 1

      def start(state) do
        a1(state)
      end
      @shortdoc "Is service available?"
      defnode a1(state), true: a3, false: a2 do
        {value, state} = available?(state)
        {value == true, state}
      end

      @shortdoc "Sorry, not available"
      defnode a2(state), do: {true, :not_available}

      if Module.defines?(__MODULE__, {:content, 1}) do
        @shortdoc "Content"
        defnode a3(state) do
          {true, content(state)}
        end
      else
        machine_error "Machine requires content/1 to operate"
      end

    end
  end

end

defmodule MyMachine do
  def content(x), do: {x}
  use SimpleMachine
end

defmodule MyMachine1 do
  def content(x), do: {x}
  use SimpleMachine

  def available?(x), do: {false, x}  
end

defmodule MyMachineNodeOverride do
  def content(x), do: {x}
  use SimpleMachine

  defoverridable a2: 1
  defnode a2(state), true: a3, do: {true, state}

  def available?(x), do: {false, x}  
end

defmodule PendingNodeMachine do
  def content(x), do: {x}
  use SimpleMachine

  defoverridable a1: 1
  defnode a1(state), true: pending(a_x), do: {true, state}

  ## silence warnings
  def test do
   a2(nil) ; a3(nil)
  end
end

defmodule Event do
  def event(v) do
    quote do
      {b, s} = unquote(v)
      {b, {:event, s}}
    end
  end
end

defmodule EventHandlingMachine do
  def content(x), do: [x]
  use SimpleMachine, event: Event

end


defmodule EflowTest do
  use ExUnit.Case

  test "simple test" do
    assert {"1"} == MyMachine.start("1")
    assert :not_available == MyMachine1.start("1")
  end

  test "overriding a node" do
    assert {"1"} == MyMachineNodeOverride.start("1")
  end

  test "pending node" do
    assert :pending == PendingNodeMachine.start("1")  
  end

  test "event handling" do
    assert {:event, [{:event,"1"}]} == EventHandlingMachine.start("1")  
  end
end
