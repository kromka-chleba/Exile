-- TODO: see about rolling an egg about to get more precise egg sounds
function animals.node_sound_egg_defaults(table)
    table = table or {}
    table.egg_hatch = table.egg_hatch or {
        name = "animals_hatch_egg",
        gain = 0.8,
        max_hear_distance = 8
    }
    nodes_nature.node_sound_defaults(table)
    return table
end

function animals.node_sound_meat_defaults(table)
    table = table or {}
    table.place = table.place or {
        name = "animals_meat_place",
        gain = 0.5
    }
    table.dug = table.dug or {
        name = "animals_meat_dug",
        gain = 1
    }
    table.dig = table.dig or {
        name = "animals_meat_dug",
        pitch = 1.3,
        gain = 0.4
    }
    table.footstep = table.footstep or {
        name = "animals_meat_place",
        pitch = 1.5,
        gain = 0.4
    }
    nodes_nature.node_sound_defaults(table)
    return table
end

-- TODO: get better sounds for cooked meat?
function animals.node_sound_meat_cooked_defaults(table)
    table = table or {}
    table.place = table.place or {
        name = "animals_meat_place",
        pitch = 1.2,
        gain = 0.4
    }
    table.dug = table.dug or {
        name = "animals_meat_dug",
        pitch = 1.2,
        gain = 0.9
    }
    table.dig = table.dig or {
        name = "animals_meat_dug",
        pitch = 1.5,
        gain = 0.3
    }
    table.footstep = table.footstep or {
        name = "animals_meat_place",
        pitch = 1.7,
        gain = 0.3
    }
    animals.node_sound_meat_defaults(table)
    return table
end
