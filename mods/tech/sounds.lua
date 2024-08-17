--
-- Tech Sounds
--

tech = tech

function tech.node_sound_glass_defaults(table)
  table = table or {}
  table.place = table.place or
    {name = "tech_glass_place", gain = 0.5}
  table.dig = table.dig or
    {name = "tech_glass_dig", gain = 0.3}
  table.dug = table.dug or
    {name = "tech_glass_dug", gain = 0.5}
  nodes_nature.node_sound_defaults(table)
  return table
end