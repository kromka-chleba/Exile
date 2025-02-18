------------------------------------
--PANDORA's BOX
--Are you sure you want to open that?
--This is for things that are strange, dangerous, creepy, insane, generally misguided etc
------------------------------------

local S = artifacts.S
local c_alpha = minimal.compat_alpha
------------------------------------
--BAD GOOD IDEAS and GOOD BAD IDEAS
--things that might even be useful, but are slightly problematic
------------------------------------

--Meta-Stim Injector
-- because you want to be a god
local function inject_metastim(itemstack, player, pointed_thing)
    --local meta = player:get_meta()
    player:set_hp(1)
    local pos = player:get_pos()

    HEALTH.add_new_effect(player, {"Meta-Stim", 1})
    --I am a GOD!
    minetest.sound_play( {name="health_superpower", gain=1},
        {pos=pos, max_hear_distance=20})
    minetest.add_particlespawner({
            amount = 80,
            time = 18,
            minpos = {x=pos.x+7, y=pos.y+7, z=pos.z+7},
            maxpos = {x=pos.x-7, y=pos.y-7, z=pos.z-7},
            minvel = {x = -5,  y = -5,  z = -5},
            maxvel = {x = 5, y = 5, z = 5},
            minacc = {x = -3, y = -3, z = -3},
            maxacc = {x = 3, y = 3, z = 3},
            minexptime = 0.2,
            maxexptime = 1,
            minsize = 0.5,
            maxsize = 2,
            texture = "health_superpower.png",
            glow = 15,
    })

    if not (minimal.player_in_creative(player)) then
        itemstack:add_wear(65535/(20-1))
    end

    -- #TODO not sure this is the correct place
    -- to upadte health formspec
    core.after(0.1, sfinv.set_player_inventory_formspec , player)

    return itemstack

end


minetest.register_tool('artifacts:metastim', {
                           description = S('Meta-Stim Injector'),
                           inventory_image = 'artifacts_metastim.png',
                           on_use = inject_metastim,
})


------------------------------------
--THE DANGEROUS AND EVIL
------------------------------------

--Exotic physics
-- a patch of space at absolute zero
local void_def = {
    description = "Void Space",
    tiles = {"artifacts_void_space.png"},
    light_source = 1,
    drawtype = "glasslike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = false,
    floodable = false,
    temp_effect = -12,
    temp_effect_max = -273,
    drop = "",
    drowning = 1,
    groups = {temp_pass = 1, temp_effect = 1},
    post_effect_color = {a = 220, r = 0, g = 0, b = 0},
    color = {a = 220, r = 0, g = 0, b = 0},
    use_texture_alpha = c_alpha.blend
}
minetest.register_node("artifacts:void_space", void_def)

local height_min = -1350
local height_max = -150

-- add exotic physics to mapgen, in addition to in Mt Meru

local exotic_in = {"group:cracky", "group:crumbly", "group:choppy", "group:snappy"}

local exotic_list = {
    --exotic matter intrusions
    { "artifacts:void_space", exotic_in,
      {offset = 0, scale = 2, spread = {x =  32, y =  32, z =  32}, seed =  21005,
       octaves = 2, persist = 0.95},  },
}

for i in ipairs(exotic_list) do
    minetest.register_ore({
            ore_type = "vein",
            ore = exotic_list[i][01],
            wherein = exotic_list[i][02],
            y_min = height_min,
            y_max = height_max,
            noise_threshold = 0.85,
            noise_params = exotic_list[i][03],
            column_height_min = 2,
            column_height_max = 6,
            random_factor = 0,
    })
end


------------------------------------
--CURIOSITIES
------------------------------------
