defmodule Eflow.Machine.Definition do
  use Behaviour

  defcallback define(opts :: any) :: any

  defmacro __using__(_) do
   module = __CALLER__.module
   quote do
     defmacro __using__(opts) do
       Eflow.Machine.Definition.__using__macro__(unquote(module), opts)
     end
   end
  end   

  def __using__macro__(module, opts) do
    define = module.define(opts)
    quote do
      import unquote(module)
      import Eflow.Machine
      use Eflow.Machine, unquote(opts)      
      unquote(define)
    end
  end

end
defmodule Eflow.Machine do
  
  defexception Error, message: nil

  defmacro __using__(opts) do
    quote location: :keep do
      import Eflow.Machine.Node
      Module.register_attribute __MODULE__, :node_doc

      def define(_), do: nil
      defoverridable define: 1

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

      def __doc__(node_name) do
        hd(lc {:node_doc, [{n, doc, shortdoc, exits}]} inlist __info__(:attributes), n == node_name, do: {shortdoc, doc})
      end

      def __nodes__(:raw) do
        lc {:node_doc, [{n, doc, shortdoc, exits}]} inlist __info__(:attributes), do: {n, {exits, doc, shortdoc}}      
      end

      def __nodes__ do
        Keyword.from_enum(__nodes__(:raw))
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
  def __defnode__({node_name, line, [arg]}, opts, caller) do
    block = opts[:do]  
    conns = lc {key, {node, _, _}} inlist opts, key != :do, do: {key, node}
    connections =  
    lc {key, node} inlist conns do
      {[key], (quote do: unquote(node)(state))}
    end
    case Macro.expand(block,caller) do
      {block_ex, _} ->
        if is_boolean(block_ex) do
          connections = Enum.filter connections, fn({[x], _}) -> x == block_ex end
        end
        unless Enum.any?(connections, fn({k, _}) -> k == block_ex end) do
           connections = connections ++ [{[{:_, line, :quoted}], (quote do: finish(state))}]
        end
      _ -> 
        connections = connections ++ [{[{:_, line, :quoted}], (quote do: finish(state))}]
    end
    connections = {:"->", line, connections}
    name = {node_name, line, [{:=, line, [arg, {:__state__, line, :quoted}]}]}
    quote do
      @node_doc {unquote(node_name), @doc, @shortdoc, unquote(conns)}
      Module.delete_attribute __MODULE__, :doc
      Module.delete_attribute __MODULE__, :shortdoc          
      defp unquote(name) do
        {result, state} = event(unquote(node_name), __state__, unquote(block))
        case result do
          unquote(connections)
        end
      end
    end
  end
end