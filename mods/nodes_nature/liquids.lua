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
            liquid_range = 3,
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
            liquid_range = 3,
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
                  puts_out_fire = 1, slippery = 3, temp_effect = 1},
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
                  puts_out_fire = 1, slippery = 3, temp_effect = 1},
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
    liquid_range = 3,
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
    liquid_range = 3,
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

        local itemdef = core.registered_nodes[dropitem]
        -- not a node, remove after 5 to 35secs
        if not itemdef then
            core.after(ran(5, 35), function()
                obj:remove()
            end)
            return
        end
        -- function for checking position and placing on success
        local check_placing -- define prior to be used by self
        check_placing = function()
            local vel = obj:get_velocity()
            if not vector.check(vel) then return end -- we got deletus
            vel = math.abs(vel.x)+math.abs(vel.y)+math.abs(vel.z)
            -- gotta wait til we stop moving
            if vel ~= 0 then
                -- check every 0.4 to 0.7 seconds
                return core.after(ran(4,7)/10, check_placing)
            end
            local newpos = obj:get_pos()
            -- LET'S PLACE THIS!!!
            local function place_item()
                obj:remove() -- remove now that we've placed
                core.set_node(newpos, {name = dropitem})
                local place_sound = itemdef.sounds and itemdef.sounds.place
                -- play place sound
                if place_sound then
                    core.sound_play(place_sound.name, minimal.merge_tables(place_sound, {pos = newpos}))
                end
                -- check falling
                if itemdef.groups and itemdef.groups.falling_node then
                    core.check_single_for_falling(newpos)
                end
            end
            newpos = vector.new(math.floor(newpos.x + 0.5), math.floor(newpos.y + 0.5), math.floor(newpos.z + 0.5))
            -- ran twice to see if we can place this
            local try_placing -- define prior to be used by self
            try_placing = function(tries)
                -- couldn't place, so remove!
                if tries and tries > 1 then obj:remove() end
                -- check up by how many tries
                newpos.y = tries and newpos.y + tries or newpos.y
                local andef = minimal.get_nodedef(newpos) -- at node definition
                -- remove nil nodes
                if not andef then
                    place_item()
                -- we can replace this pesky node (if not lava and is buildable_to)
                elseif andef.name ~= "nodes_nature:lava_source" and andef.buildable_to then
                    place_item()
                -- keeps trying until limit is reached (2)
                else
                    try_placing(tries and tries + 1 or 1)
                end
            end
            try_placing()
        end
        -- begin checks after 0.8 to 1.8 seconds
        core.after(ran(8,18)/10, check_placing)
    end
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
            minetest.set_node(pos, {name = "nodes_nature:lava_flowing", param2=10})
            local posa =   {x = pos.x, y = pos.y+1, z = pos.z}
            lava_particle(posa)
            aname = minetest.get_node(posa).name
        else
            break
        end
    end
    if height == 0 then return end -- couldn't even erupt
    local gain = 5*(height/7)
    minimal.sound_play("nodes_nature_erupt_lava",{pos = pos, gain = {gain,gain*1.3}, pitch = {0.75, 1.35}, max_hear_distance=50})
end

-- utilized quite a few times across code, requires pos for playing at a position
-- randomizes gain and pitch
local function lava_cool_sound(pos)
    minimal.sound_play("nodes_nature_cool_lava",
        {pos = pos, max_hear_distance = 16, gain = {0.18,0.28}, pitch = {0.8, 1.2}})
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
        lava_cool_sound(pos)
        minetest.check_for_falling(pos)
        --TODO: steam explosion effects
        return
    end



    --add hot air
    climate.air_temp_source(pos, lava_temp_effect, lava_heater, 0.5, 15)

    --what's above?
    local posa = vector.new(pos.x, pos.y+1, pos.z)
    local anode = core.get_node(posa).name
    anode = core.registered_nodes[anode] or {name=anode, buildable_to=true} -- ensure no issues with undefined nodes

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
            -- randomize to prevent sound barrier breaking
            core.after(ran(5,115)/10, function() -- max should be a BIT more than the lava interval
                erupt(pos, anode.name, 2 + gpos)
            end)
        end

        local posu = vector.new(pos.x, pos.y-1, pos.z) -- pos under
        local unode = core.get_node(posu).name -- under node
        unode = core.registered_nodes[unode] or {name=unode} -- ensure no issues with undefined nodes
        -- can throw rocks if not a defined node or if not walkable or not a lava_source
        local flying = not unode and true or not (unode.walkable or unode.name == "nodes_nature:lava_source") and true

        --cool source to basalt, or melt above
        if nodename == "nodes_nature:lava_source" then

            if not flying and ran()>0.15 then

                -- maybe use a find node check instead? checking for more than 3 to 5 source nodes?
                local temp = climate.get_point_temp(posa)
                local stillmelted = ran() < temp/980
                if stillmelted then return end
                minetest.set_node(pos, {name = "nodes_nature:basalt"})
                lava_cool_sound(pos)

            elseif minetest.get_item_group(anode.name, "cracky") > 0
                or minetest.get_item_group(anode.name, "crumbly") > 0 then

                --check it has "force" nearby
                if gpos > 8 then -- We ran this check already, reuse it
                    --melt above
                    lava_particle(posa)
                    minetest.set_node(posa, {name = "nodes_nature:lava_source"})
                    lava_cool_sound(posa)
                end
            end
        -- flowing will solidy the air node and leave tunnels
        -- launches rocks
        elseif nodename == "nodes_nature:lava_flowing" then

            --place stone blocks
            if not flying then
                -- still melty if node param2 is greater than 6 or lava underneath
                -- otherwise random chance with node.param2 divided by 7
                local stillmelted = (node.param2 > 6 or unode.name:match("lava")) and true or ran() > node.param2/7
                if stillmelted then return end
                -- nearing the end of our line, chance to become basalt
                local basaltchance = node.param2 < 6 and ran() > node.param2/6
                if basaltchance then
                    core.set_node(pos, {name = "nodes_nature:basalt"})
                else
                    core.set_node(pos_air, {name = "nodes_nature:scoria"})
                    climate.air_temp_source(pos, lava_temp_effect,
                                            lava_heater, 0.5, 15)
                end
                lava_cool_sound(pos)
            -- THROW DA BOULDER!
            elseif ran()>0.95 then
                eject_drops("nodes_nature:scoria_boulder", pos, gpos)
            end
        end

    end

end




minetest.register_abm({
        label = "Lava actions",
        nodenames = {"nodes_nature:lava_source", "nodes_nature:lava_flowing"},
        --neighbors = {"group:cracky", "group:crumbly", 'air', 'climate:air_temp'},
        interval = 10,
        chance = 3,
        catch_up = true, -- deal with volcanoes
        action = function(...)
            lava_actions(...)
        end,
})
