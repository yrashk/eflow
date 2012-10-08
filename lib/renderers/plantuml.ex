defmodule Eflow.Renderer.Plantuml do
  
  def render(machine, opts // []) do
    nodes = machine.__nodes__
    image = opts[:image] || "#{to_binary(machine)}.png"
    "@startuml #{image}" <>
    list_to_binary(lc n inlist nodes, do: node_diagram(n)) <>
    "\n@enduml"
  end

  defp node_diagram({name, {pos, neg, _doc, shortdoc}}) do
    %b|
     state "#{name}" as #{shortname(name)}
     #{shortname(name)} : #{shortdoc}
     #{shortname(name)} --> #{shortname(pos)} : true
     #{shortname(name)} --> #{shortname(neg)} : false
    |
  end

  defp shortname(:finish), do: "[*]"
  defp shortname(name), do: :erlang.phash2(name)
end