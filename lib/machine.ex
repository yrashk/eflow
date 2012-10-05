defmodule Eflow.Machine do
  
  defexception Error, message: nil

  defmacro __using__(opts) do
    if opts == [], do: opts = [node: Eflow.Machine.Node]
    quote do
      import Eflow.Machine
      import unquote(opts[:node])

      def finish(state), do: state
      defoverridable finish: 1

      def pending(state), do: :pending
      defoverridable pending: 1
    end
  end

  def machine_error(message), do: raise Error.new(message: message)
end

defmodule Eflow.Machine.Node do
  defmacro defnode(name, opts, [do: block]) do
    __defnode__(name, Keyword.put(opts, :do, block))
  end
  defmacro defnode(name, opts) do
    __defnode__(name, opts)
  end
  def __defnode__(name, opts) do
    pos = opts[:true] || quote do: finish
    {pos, _, _} = pos
    neg = opts[:false] || quote do: finish
    {neg, _, _} = neg
    block = opts[:do]
    quote do
      defp unquote(name) do
        {result, new_state} = unquote(block)
        case result do
          true -> unquote(pos).(new_state)
          false -> unquote(neg).(new_state)
        end
      end
    end
  end
end