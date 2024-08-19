--
-- Tech Sounds
--

tech = tech

function tech.node_sound_glass_defaults(table)
  table = table or {}
  table.place = table.place or
    {name = "tech_glass_place", gain = 0.7}
  table.dig = table.dig or
    {name = "tech_glass_dig", gain = 0.4}
  table.dug = table.dug or
    {name = "tech_glass_dug", gain = 0.7}
  table.footstep = table.footstep or
    {name = "tech_glass_dig", gain = 0.2, pitch = 0.82}
  nodes_nature.node_sound_defaults(table)
  return table
end