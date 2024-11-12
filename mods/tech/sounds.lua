--
-- Tech Sounds
--

tech = tech

-- earthenware/ceramics
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

-- glasses
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

-- metallic
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

-- interactive vessels
-- MUST BE PLAYED with minimal.sound_play
function tech.interact_sound_cooking_vessel(table)
    table = table or {}
    table.frying = table.frying or table.frying ~= false and {
        name = "tech_frying", gain = {2,6}, fade = 0.4, max_hear_distance = 10,
    } or nil
    table.frying_start = table.frying_start or table.frying_start ~= false and {
        name = "tech_frying_start", gain = 1, fade = 1, max_hear_distance = 12
    } or nil
    table.frying_final = table.frying_final or table.frying_final ~= false and {
        name = "tech_frying_final", gain = 2, fade = 0.1, max_hear_distance = 13
    } or nil
    return table
end

-- foody
-- breads
-- TODO: see about getting "crunchy" bread and true unleavened sounds
-- sounds are just sounds of me interacting with a soft croissant - TPH
function tech.node_sound_bread_unleavened_defaults(table)
    table = table or {}
    table.place = table.place or
        {name = "tech_bread_place", gain = 0.35, pitch = 1.05}
    table.dug = table.dug or
        {name = "tech_bread_place", gain = 0.35, pitch = 0.9}
    table.footstep = table.footstep or
        {name = "tech_bread_footstep", gain = 0.15}
    table.dig = table.dig or
        {name = "tech_bread_footstep",
        gain = 0.3, pitch = 1.3}
    nodes_nature.node_sound_dirt_defaults(table)
    return table
end

function tech.node_sound_bread_defaults(table)
    table = table or {}
    table.place = table.place or
        {name = "tech_bread_place"}
    table.dug = table.dug or
        {name = "tech_bread_place", pitch = 0.85}
    table.footstep = table.footstep or
        {name = "tech_bread_footstep", gain = 0.2}
    table.dig = table.dig or
        {name = "tech_bread_footstep",
        gain = 0.35, pitch = 1.2}
    tech.node_sound_bread_unleavened_defaults(table)
    return table
end

-- for fine powders like salt or sugar
function tech.node_sound_powder_defaults(table)
    table = table or {}
    table.footstep = table.footstep or
        {name = "tech_powder_footstep", gain = 0.15}
    table.place = table.place or
        {name = "tech_powder_place", gain = 0.5}
    table.dig = table.dig or
        {name = "tech_powder_footstep", gain = 0.24, pitch = 1.2}
    table.dug = table.dug or
        {name = "tech_powder_place", gain = 0.5, pitch = 0.85}
    nodes_nature.node_sound_defaults(table)
    return table
end
