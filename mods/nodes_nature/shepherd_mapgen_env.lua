local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local ms = mapchunk_shepherd

-- Surface detection using heightmap
-- This labels mapblocks at the surface for seasonal soil and moisture
ms.create_surface_finder({
    margin = 1  -- Include 1 block above and below exact surface
})

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
