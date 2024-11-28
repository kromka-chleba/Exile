--
-- Tech Sounds
--

tech = tech

function tech.node_sound_earthenware_defaults(table)
    table = table or {}
    table.place = table.place or {
        name = "tech_ceramic_place",
        pitch = 0.8
    }
    table.dig = table.dig or {
        name = "tech_ceramic_dig",
        pitch = 0.95,
    }
    table.dug = table.dug or {
        name = "tech_ceramic_place",
        pitch = 0.9
    }
    table.footstep = table.footstep or {
        name = "tech_ceramic_dig",
        pitch = 1.05,
        gain = 0.3
    }
    nodes_nature.node_sound_stone_defaults(table)
    return table
end

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

function tech.node_sound_metal_defaults(table)
    table = table or {}
    table.place = table.place or
        {name = "tech_metal_place", gain = 0.5}
    table.dig = table.dig or table.dig ~= false and
        {name = "tech_metal_dig", gain = 0.35} or nil
    table.dug = table.dug or
        {name = "tech_metal_dig", gain = 0.6, pitch = 0.84}
    table.footstep = table.footstep or
        {name = "tech_metal_place", gain = 0.3, pitch = 0.85}
    nodes_nature.node_sound_defaults(table)
    return table
end

function tech.node_sound_metal_hollow_defaults(table)
    table = table or {}
    table.place = table.place or
        {name = "tech_metal_hollow_place", gain = 0.6}
    table.dug = table.dug or
        {name = "tech_metal_hollow_dug", gain = 0.6}
    table.footstep = table.footstep or
        {name = "tech_metal_hollow_place", gain = 0.3, pitch = 0.85}
    tech.node_sound_metal_defaults(table)
    return table
end
