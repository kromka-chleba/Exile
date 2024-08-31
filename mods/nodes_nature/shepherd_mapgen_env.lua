local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local ms = mapchunk_shepherd

dofile(mod_path.."/shepherd_labels.lua")

-- Finds ocean
ms.create_biome_finder({
        biome_list = {
            "Shallow Water",
            "Deep Water",
            "Sandy Beach",
            "Silty Beach",
            "Gravel Beach",
            "Sandy Coast",
            "Silty Coast",
            "Gravel Coast",
        },
        add_labels = {
            "ocean",
        }
})

ms.create_biome_finder({
        biome_list = {
            "Sandy Beach",
            "Silty Beach",
            "Gravel Beach",
            "Sandy Coast",
            "Silty Coast",
            "Gravel Coast",
        },
        add_labels = {
            "coast",
        }
})

ms.create_biome_finder({
        biome_list = {
            "Highland",
            "Highland Scree",
            "Highland Rock",
        },
        add_labels = {
            "mountains",
        }
})
