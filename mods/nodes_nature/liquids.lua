---------------------------------------------------------
--LIQUIDS
--

-- Internationalization
local S = nodes_nature.S

local ran = math.random

local c_alpha = minimal.compat_alpha

--Water
local list = {
    {name = "salt_water",
     desc = S("Salt Water"),
     water_g = 2,
     post_alpha = 140,
     renew = true,
    },
    {name = "freshwater",
     desc = S("Freshwater"),
     water_g = 1,
     post_alpha = 100,
     renew = false
    },
}

local function try_mixing_into(pos, name, state)
    local water_table = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y, z = pos.z + 1},
        {"nodes_nature:"..name.."_source"})
    if #water_table > 0 then
        state.replaced = true
    end
end

local function get_after_destruct(name, renewable)
    return function (pos, oldnode)
        local node = minetest.get_node(pos)
        if node.name == "air" or
            node.name == "nodes_nature:"..name.."_flowing" then
            return
        end
        local state = {replaced = false}
        local function try_overflowing(level)
            if state.replaced then return end
            local lev = level or 0
            local air_table = minetest.find_nodes_in_area(
                {x = pos.x - 1, y = pos.y + lev, z = pos.z - 1},
                {x = pos.x + 1, y = pos.y + lev, z = pos.z + 1},
                {"air", "nodes_nature:"..name.."_flowing"})
            if #air_table > 0 then
                local air_pos = air_table[math.random(1, #air_table)]
                state.replaced = true
                minetest.set_node(air_pos, {name = oldnode.name})
            end
        end
        local function to_the_surface()
            if state.replaced then return end
            local new_pos = vector.new(pos)
            for i = 1, 100 do
                new_pos.y = new_pos.y + 1
                local newnode = minetest.get_node(new_pos)
                if newnode.name == "air" or
                    newnode.name == "nodes_nature:"..name.."_flowing" then
                    state.replaced = true
                    minetest.set_node(new_pos, {name = oldnode.name})
                    break
                elseif newnode.name ~= "nodes_nature:"..name.."_source" then
                    -- we hit a ceiling
                    break
                end
            end
        end
        if renewable then
            try_mixing_into(pos, name, state)
        end
        try_overflowing(-1)
        try_overflowing()
        try_overflowing(1)
        to_the_surface()
    end
end

for _, water in pairs(list) do
    local name = water.name
    local desc = water.desc
    local water_g = water.water_g
    local alpha = c_alpha.blend
    local post_alpha = water.post_alpha
    local renew = water.renew

    minetest.register_node(
        "nodes_nature:"..name.."_source", {
            description = S("@1 Source", desc),
            drawtype = "liquid",
            tiles = {
                {
                    name = "nodes_nature_"..name.."_source_animated.png",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 2.0,
                    },
                },
                {
                    name = "nodes_nature_"..name.."_source_animated.png",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 2.0,
                    },
                },
            },
            use_texture_alpha = alpha,
            paramtype = "light",
            walkable = false,
            pointable = false,
            diggable = false,
            buildable_to = true,
            is_ground_content = false,
            drop = "",
            drowning = 1,
            liquidtype = "source",
            liquid_alternative_flowing = "nodes_nature:"..name.."_flowing",
            liquid_alternative_source = "nodes_nature:"..name.."_source",
            liquid_viscosity = 1,
            liquid_range = 0,
            liquid_renewable = renew,
            post_effect_color = {a = post_alpha, r = 30, g = 60, b = 90},
            groups = {water = water_g, cools_lava = 1,
                      puts_out_fire = 1, falling_node = 1, float = 1},
            sounds = nodes_nature.node_sound_water_defaults(),
            after_destruct = get_after_destruct(name, renew),
            on_construct = function (pos)
                minetest.check_single_for_falling(pos)
            end,
    })

    minetest.register_node(
        "nodes_nature:"..name.."_flowing", {
            description = S("@1 Flowing", desc),
            drawtype = "flowingliquid",
            tiles = {"nodes_nature_"..name..".png"},
            special_tiles = {
                {
                    name = "nodes_nature_"..name.."_flowing_animated.png",
                    backface_culling = false,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 0.8,
                    },
                },
                {
                    name = "nodes_nature_"..name.."_flowing_animated.png",
                    backface_culling = true,
                    animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 0.8,
                    },
                },
            },
            use_texture_alpha = alpha,
            paramtype = "light",
            paramtype2 = "flowingliquid",
            walkable = false,
            pointable = false,
            diggable = false,
            buildable_to = true,
            is_ground_content = false,
            liquid_move_physics = false,
            move_resistance = 0,
            drop = "",
            drowning = 1,
            liquidtype = "flowing",
            liquid_range = 2,
            liquid_alternative_flowing = "nodes_nature:"..name.."_flowing",
            liquid_alternative_source = "nodes_nature:"..name.."_source",
            liquid_viscosity = 1,
            liquid_renewable = renew,
            post_effect_color = {a = post_alpha, r = 30, g = 60, b = 90},
            groups = {water = water_g, not_in_creative_inventory = 1,
                      puts_out_fire = 1, cools_lava = 1},
            sounds = nodes_nature.node_sound_water_defaults(),
    })
end



-----------------------------
--Drink Liquids with weild hand

--make freshwater drinkable on click
minetest.override_item(
    "nodes_nature:freshwater_source", {
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            if not minetest.is_player(clicker) then
                return
            end
            local meta = clicker:get_meta()
            local thirst = meta:get_int("thirst")
            --only drink if thirsty
            if thirst < 100 then

                local water = 100
                thirst = thirst + water
                if thirst > 100 then
                    thirst = 100
                end

                meta:set_int("thirst", thirst)
                --remove so don't get infinity water supply
                minetest.set_node(pos, {name = "air"})
                minetest.sound_play("nodes_nature_slurp",
                                    {pos = pos, max_hear_distance = 3,
                                     gain = 0.25})

                --food poisoning
                local c = 0.005
                --parasites
                local c2 = 0.005

                --disease chance worse if water in a bad place (e.g. a muddy hole)
                local bad = minetest.find_node_near(pos, 1, {"group:sediment"})
                if bad then
                    c = 0.15
                    c2 = 0.15
                end

                --food poisoning
                if ran() < c then
                    HEALTH.add_new_effect(clicker, {"Food Poisoning", 1})
                end

                --parasites
                if ran() < c2 then
                    HEALTH.add_new_effect(clicker, {"Intestinal Parasites"})
                end
            end
        end
})

minetest.override_item(
    "nodes_nature:salt_water_source", {
        color = "#90ff95",
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            if not minetest.is_player(clicker) then
                return
            end
            minetest.chat_send_player(clicker:get_player_name(),
                                      S("Salt water is not safe to drink."))
        end
})

minetest.override_item(
    "nodes_nature:salt_water_flowing",{
        color = "#99ff95",
})

----------------------------------------------------------
--SNOW AND ICE (yes I know this isn't a liquid...in this state)

--Snow

minetest.register_node(
    "nodes_nature:snow", {
        description = S("Snow"),
        tiles = {"nodes_nature_snow.png"},
        stack_max = minimal.stack_max_bulky *2,
        paramtype = "light",
        floodable = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
        },
        temp_effect = -2,
        temp_effect_max = 0,
        groups = {crumbly = 3, falling_node = 1, temp_effect = 1, temp_pass = 1,
                  puts_out_fire = 1, fall_damage_add_percent = -25,
                  edible = 1, no_soup = 1},
        sounds = nodes_nature.node_sound_snow_defaults(),
        _use_tip = S("Combine with another slab\n or eat if you're desperate"),
        _combines_by_hand = "nodes_nature:snow_block",
        _on_use_item = function(player, wielded_item, pointed_thing)
            if pointed_thing and pointed_thing.type == "node"
                and minetest.get_node(pointed_thing.under).name ==
                "nodes_nature:snow_block" then
                -- do not accidentally eat snow when combining slabs
                return
            end

            return minimal.slabs_combine(player, wielded_item, minimal.get_usable_position(pointed_thing))
            or wielded_item:get_definition()._on_consume(player,
                                                         wielded_item,
                                                         pointed_thing)
        end,
})

minetest.register_node(
    "nodes_nature:snow_block", {
        description = S("Snow Block"),
        tiles = {"nodes_nature_snow.png"},
        stack_max = minimal.stack_max_bulky,
        temp_effect = -4,
        temp_effect_max = 0,
        _splits_by_hand = "nodes_nature:snow",
        _on_use_node = minimal.slabs_split_hand,
        _use_tip = S("Eat if you're desperate"),
        groups = {crumbly = 3, falling_node = 1, temp_effect = 1,
                  puts_out_fire = 1, cools_lava = 1,
                  fall_damage_add_percent = -50, edible = 1, no_soup = 1,
        },
        sounds = nodes_nature.node_sound_snow_defaults(),
})

-- hand_mixing
-- (I think mixing_spot is the old v3 station)

crafting.register_recipe({
        type = {"mixing_spot","hand_mixing"},
        output = "nodes_nature:snow_block",
        items = {"nodes_nature:snow 2"},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = {"mixing_spot","hand_mixing"},
        output = "nodes_nature:snow 2",
        items = {"nodes_nature:snow_block"},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = {"mixing_spot","hand_mixing"},
        output = "nodes_nature:snow_block 2",
        items = {"nodes_nature:ice"},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = {"mixing_spot","hand_mixing"},
        output = "nodes_nature:ice",
        items = {"nodes_nature:snow_block 2"},
        level = 1,
        always_known = true,
})

--ice
minetest.register_node(
    "nodes_nature:ice", {
        description = S("Ice"),
        tiles = {"nodes_nature_ice.png"},
        stack_max = minimal.stack_max_bulky,
        paramtype = "light",
        use_texture_alpha = c_alpha.blend,
        temp_effect = -4,
        temp_effect_max = 0,
        groups = {cracky = 3, crumbly = 1, cools_lava = 1,
                  puts_out_fire = 1, slippery = 3,
                  temp_effect = 1, craft_ground = 1},
        sounds = nodes_nature.node_sound_ice_defaults(),
})


--sea ice
--for thawing, so it turns back into salt water
minetest.register_node(
    "nodes_nature:sea_ice", {
        description = S("Sea Ice"),
        tiles = {"nodes_nature_ice.png"},
        paramtype = "light",
        drop = "nodes_nature:ice",
        use_texture_alpha = c_alpha.blend,
        temp_effect = -4,
        temp_effect_max = 0,
        groups = {cracky = 3, crumbly = 1, cools_lava = 1,
                  puts_out_fire = 1, slippery = 3,
                  temp_effect = 1, craft_ground = 1},
        sounds = nodes_nature.node_sound_ice_defaults(),
})


--------------------------------------------------------------------
--LAVA
local lava_light = 12
local lava_temp_effect = 60
local lava_heater = 1200

local lava_source = {
    description = S("Lava Source"),
    drawtype = "liquid",
    tiles = {
        {
            name = "nodes_nature_lava_source_animated.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 3.0,
            },
        },
        {
            name = "nodes_nature_lava_source_animated.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 3.0,
            },
        },
    },
    paramtype = "light",
    light_source = lava_light,
    temp_effect = lava_temp_effect,
    temp_effect_max = lava_heater,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    drowning = 1,
    liquidtype = "source",
    liquid_alternative_flowing = "nodes_nature:lava_flowing",
    liquid_alternative_source = "nodes_nature:lava_source",
    liquid_viscosity = 7,
    liquid_renewable = false,
    damage_per_second = 4 * 2,
    post_effect_color = {a = 191, r = 255, g = 64, b = 0},
    groups = {igniter = 1, temp_effect = 1, temp_pass = 1},
}

local lava_flowing = {
    description = S("Flowing Lava"),
    drawtype = "flowingliquid",
    tiles = {"nodes_nature_lava.png"},
    special_tiles = {
        {
            name = "nodes_nature_lava_flowing_animated.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 3.3,
            },
        },
        {
            name = "nodes_nature_lava_flowing_animated.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 3.3,
            },
        },
    },
    paramtype = "light",
    paramtype2 = "flowingliquid",
    light_source = lava_light,
    temp_effect = lava_temp_effect,
    temp_effect_max = lava_heater,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    drowning = 1,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nodes_nature:lava_flowing",
    liquid_alternative_source = "nodes_nature:lava_source",
    liquid_viscosity = 7,
    liquid_renewable = false,
    damage_per_second = 4 * 2,
    post_effect_color = {a = 191, r = 255, g = 64, b = 0},
    groups = {igniter = 1, not_in_creative_inventory = 1,
              temp_effect = 1, temp_pass = 1},
}

minetest.register_node("nodes_nature:lava_flowing", lava_flowing)

minetest.register_node("nodes_nature:lava_source", lava_source)



-----
-----
--eject rocks
local function eject_drops(dropitem, pos, speed)
    local drop_pos = vector.new(pos)

    local obj = minetest.add_item(drop_pos, dropitem)
    if obj then
        obj:get_luaentity().collect = true
        obj:set_acceleration({x = 0, y = -10, z = 0})
        obj:set_velocity({
                x = ran(-speed, speed),
                y = ran(speed, speed + speed),
                z = ran(-3, 3)
        })

        --placeholder to tidy up
        minetest.after(6, function()
                           obj:remove()
        end)


    end
    -- TODO: make these land as placed nodes, not items
end



--particle effects
local function lava_particle(pos)

    local particle = {
        amount = 3,
        time = 0.5,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.50, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y, z = pos.z + 0.5},
        minvel = {x= -2, y= 1, z= -2},
        maxvel = {x= 2, y= 6, z= 2},
        minacc = {x= 0, y= -10, z= 0},
        maxacc = {x= 0, y= 0, z= 0},
        minexptime = 0.5,
        maxexptime = 2.5,
        minsize = 0.4,
        maxsize = 1,
        collisiondetection = true,
        vertical = false,
        node = {name = "nodes_nature:lava_source", param2 = 0},
    }

    minetest.add_particlespawner(particle)

end




--plumes
local erupt = function(pos, aname, h)

    local height = 0
    --erupt
    while (aname == "air" or aname == "climate:air_temp"
           or aname == "nodes_nature:lava_flowing") and height < h do
        if ran()<0.8 then
            height = height + 1
            pos.y = pos.y + 1
            minetest.set_node(pos, {name = "nodes_nature:lava_flowing"})
            local posa =   {x = pos.x, y = pos.y+1, z = pos.z}
            lava_particle(posa)
            aname = minetest.get_node(posa).name
        else
            break
        end
    end
    if math.random() < 0.01 then
        -- We don't want to play this too often otherwise the sound is glitchy
        minetest.sound_play("nodes_nature_erupt_lava", {pos = pos,
                                                        max_hear_distance = 50,
                                                        gain = 5})
    end
end


--cools when exposed to air, melts solids, adds plumes
local lava_actions = function(pos, node)

    --do cooling
    --TODO: this needs to happen instantly and explosively.
    -- Currently its a slow unreliable wait.
    local coolpos = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y, z = pos.z + 1},
        {"group:cools_lava"}
    )
    if #coolpos > 0 then
        --or climate.get_snow(pos)
        --or climate.get_rain(pos) then
        --these cool things in caves, possibly due to lava being a light source
        lava_particle(pos)
        minetest.set_node(pos, {name = "nodes_nature:volcanic_ash"})
        -- PLACEHOLDER! Ash is not technically correct, should be black sand
        minetest.sound_play("nodes_nature_cool_lava", {pos = pos,
                                                       max_hear_distance = 16,
                                                       gain = 0.25})
        minetest.check_for_falling(pos)
        --TODO: steam explosion effects
        return
    end



    --add hot air
    climate.air_temp_source(pos, lava_temp_effect, lava_heater, 0.5, 15)

    --what's above?
    local posa =         {x = pos.x, y = pos.y+1, z = pos.z}
    local aname = minetest.get_node(posa).name

    --exposed to air?
    local pos_air = minetest.find_node_near(pos, 1, {"air", "climate:air_temp"})

    --differences between flowing and source
    local nodename = node.name

    --get force
    local gpos = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y, z = pos.z + 1},
        {"nodes_nature:lava_source", "nodes_nature:lava_flowing" }
    )
    gpos = #gpos

    --[[
        --melt things back into lava e.g. to stop boulders accumulating inside the volcano
        --the necessity of this depends on how rock launching lava bombs work
        local melt_list = {
        'nodes_nature:scoria_cobble1', 'nodes_nature:scoria_cobble2', 'nodes_nature:scoria_cobble3',
        'nodes_nature:scoria_boulder',
        'nodes_nature:basalt_cobble1', 'nodes_nature:basalt_cobble2', 'nodes_nature:basalt_cobble3',
        'nodes_nature:basalt_boulder',
        }
        local pos_melt = minetest.find_node_near(pos, 1, melt_list)
        if gpos > 12 and pos_melt then --needs to be high or lava flows melt every surface boulder
        minetest.set_node(pos_melt, {name = "nodes_nature:lava_source"})
        minetest.sound_play("nodes_nature_cool_lava",     {pos = pos, max_hear_distance = 16, gain = 0.25})
        end
    ]]

    if pos_air then

        --do eruption
        if gpos > 8 and ran() > 0.63 then
            erupt(pos, aname, 2 + gpos)
            --spread instability
            local spos = minetest.find_node_near(pos, 1,
                                                 {'nodes_nature:lava_source',
                                                  "nodes_nature:lava_flowing"})
            if spos then
                local pa =  {x = pos.x, y = pos.y+1, z = pos.z}
                local an = minetest.get_node(pa).name
                if an == 'air' or an == 'climate:air_temp'
                    or an == "nodes_nature:lava_flowing" then

                    minetest.after(ran(0.5,1), function()
                                       erupt(spos, an, 1)
                    end)
                end
            end
        end

        local flying = false
        local pos_under = {x = pos.x, y = pos.y-1, z = pos.z}
        local under_name = minetest.get_node(pos_under).name
        local nodedef = minetest.registered_nodes[under_name]
        local walkable = nodedef.walkable
        if not nodedef or not walkable then
            if under_name ~= "nodes_nature:lava_source" then
                flying = true
            end
        end

        --cool source to basalt, or melt above
        if nodename == "nodes_nature:lava_source" then

            if flying == false and ran()>0.15 then

                minetest.set_node(pos, {name = "nodes_nature:basalt"})
                minetest.sound_play("nodes_nature_cool_lava",
                                    {pos = pos, max_hear_distance = 16,
                                     gain = 0.25})

            elseif minetest.get_item_group(aname, "cracky") > 0
                or minetest.get_item_group(aname, "crumbly") > 0 then

                --check it has "force" nearby
                if gpos > 8 then -- We ran this check already, reuse it
                    --melt above
                    lava_particle(posa)
                    minetest.set_node(posa, {name = "nodes_nature:lava_source"})
                    minetest.sound_play("nodes_nature_cool_lava",
                                        {pos = pos, max_hear_distance = 16,
                                         gain = 0.25})
                end
            end

            --flowing will solidy the air node and leave tunnels
            -- launches rocks
        elseif nodename == "nodes_nature:lava_flowing" then

            --place stone
            if flying == false then
                if ran()<0.75 then
                    minetest.set_node(pos_air, {name = "nodes_nature:scoria"})
                    climate.air_temp_source(pos, lava_temp_effect,
                                            lava_heater, 0.5, 15)
                else
                    minetest.set_node(pos, {name = "nodes_nature:basalt"})
                end

            elseif ran()>0.95 then
                --minetest.set_node(pos, {name = "nodes_nature:scoria_boulder"})
                --minetest.check_for_falling(pos)
                eject_drops("nodes_nature:scoria_boulder", pos, gpos)
            end

            minetest.sound_play("nodes_nature_cool_lava",
                                {pos = pos, max_hear_distance = 16, gain = 0.25})
            return
        end

    end

end




minetest.register_abm({
        label = "Lava actions",
        nodenames = {"nodes_nature:lava_source", "nodes_nature:lava_flowing"},
        --neighbors = {"group:cracky", "group:crumbly", 'air', 'climate:air_temp'},
        interval = 10,
        chance = 3,
        catch_up = false,
        action = function(...)
            lava_actions(...)
        end,
})
