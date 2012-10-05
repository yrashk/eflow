defmodule Eflow.Machine do
  
  defexception Error, message: nil

  defmacro __using__(opts) do
    quote do
      import Eflow.Machine
      import Eflow.Machine.Node
      Module.register_attribute __MODULE__, :node_doc

      def finish(state), do: state
      defoverridable finish: 1

      def pending(state), do: :pending
      defoverridable pending: 1

      defmacro event(n, state, value) do
        case unquote(opts[:event]) do
          nil -> value
          {module, f} -> apply(module,f, [n, state, value])
          {module, f, args} -> apply(module,f, [n, state, value|args])
          module when is_atom(module) -> apply(module, :event, [n, state, value])
          _ -> value
        end
      end

      def doc(node_name) do
        hd(lc {:node_doc, [{n, doc, shortdoc}]} inlist __info__(:attributes), n == node_name, do: {shortdoc, doc})
      end

    end
  end

  def machine_error(message), do: raise Error.new(message: message)
end

defmodule Eflow.Machine.Node do
  defmacro defnode(name, opts, [do: block]) do
    __defnode__(name, Keyword.put(opts, :do, block), __CALLER__)
  end
  defmacro defnode(name, opts) do
    __defnode__(name, opts, __CALLER__)
  end
  def __defnode__(name, opts, _caller) do
    pos = opts[:true] || quote do: finish
    {pos, _, _} = pos
    neg = opts[:false] || quote do: finish
    {neg, _, _} = neg
    block = opts[:do]
    {node_name, line, [arg]} = name
    name = {node_name, line, [{:=, line, [arg, {:__state__, line, :quoted}]}]}
    quote do
      @node_doc {unquote(node_name), @doc, @shortdoc}
      Module.delete_attribute __MODULE__, :doc
      Module.delete_attribute __MODULE__, :shortdoc          
      defp unquote(name) do
        {result, state} = event(unquote(node_name), __state__, unquote(block))
        case result do
          true -> unquote(pos).(state)
          false -> unquote(neg).(state)
        end
      end
    end
  end
end