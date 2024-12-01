
------------------------------------
--TOOLS
--for debug, and gameplay
------------------------------------

mobkit = mobkit
minimal = minimal
local hud_type = minimal.hud_type

local S = artifacts.S

------------------------------------
--Base Data + functions
------------------------------------
local cc = {
    "#00ff00", -- title, lime green
    "#cc6600", -- data, brownish orange
}

local function chat_display(name, label, value)
    minetest.chat_send_player(name, minetest.colorize(cc[1], label))
    minetest.chat_send_player(name, minetest.colorize(cc[2], value))
end

local function chat_data(name, msg)
    minetest.chat_send_player(name, minetest.colorize(cc[2], msg))
end
------------------------------------
--LIGHT METER
--get positon light
------------------------------------

local light_meter = function(user, pointed_thing)

    local name =user:get_player_name()

    local measure
    if pointed_thing and pointed_thing.type == "node" then
        local tgt = pointed_thing.under
        measure = vector.check(tgt) and minetest.get_node_light(tgt) or nil
        if measure == 0 then
            -- It's a solid node, the user probably wants the spot above instead
            tgt = pointed_thing.over
            measure = vector.check(tgt) and minetest.get_node_light(tgt) or nil
        end
    end
    if not measure then
        local pos = user:get_pos()
        measure = ((minetest.get_node_light({x = pos.x,
                                             y = pos.y,
                                             z = pos.z})) or 0)
    end
    chat_display(name, S("LIGHT MEASUREMENT:"),
        S("LIGHT LEVEL = @1", tostring(measure)))
end


minetest.register_craftitem("artifacts:light_meter", {
    description = S("Light Meter"),
    inventory_image = "artifacts_light_meter.png",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        light_meter(user, pointed_thing)
    end,
    _dig_tip = S("List light level of node or self"),
    -- probe light of self
    _on_use_item = function(user, itemstack, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        light_meter(user, {ref = user, type = "object"})
    end,
})

------------------------------------
-- General probe setup
------------------------------------

local function init_probe(user, pointed_thing)
    if pointed_thing.type ~= "node" then
        return
    end

    local under = minetest.get_node(pointed_thing.under)
    local param2 = under.param2
    local nodedef = minetest.registered_nodes[under.name]
    if not nodedef then
        return
    end
    local name = user:get_player_name()
    local meta = minetest.get_meta(pointed_thing.under)
    return  name, meta, nodedef, param2
end

-- converts meta into a table for easier checks
local function init_probe_readonly(user, pointed_thing)
    local params = {init_probe(user, pointed_thing)}
    -- no meta parameter, return!
    if not params[2] then return end
    params[2] = params[2]:to_table() or {fields={}} -- meta
    return unpack(params)
end


------------------------------------
--TEMPERATURE PROBE
--get node temperature
------------------------------------

local temp_probe = function(user, pointed_thing)

    local name = init_probe(user, pointed_thing)
    if not name then
        return
    end
    local temp = climate.get_point_temp(pointed_thing.under)
    local measure = climate.get_temp_string(temp, user:get_meta())

    chat_display(name,
                 S("OBJECT TEMPERATURE MEASUREMENT:"),
                 S("TEMPERATURE = "))
    chat_data(name, measure)
    --minetest.sound_play("ecobots2_tool_good",
    -- {gain = 0.2, pos = pos, max_hear_distance = 5})
end


minetest.register_craftitem("artifacts:temp_probe", {
    description = S("Temperature Probe"),
    inventory_image = "artifacts_temp_probe.png",
    wield_image = "artifacts_temp_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        temp_probe(user, pointed_thing)
    end,
    _dig_tip = S("List temperature of node")
})

------------------------------------
--FUEL PROBE
--get burn progress
------------------------------------

local fuel_probe = function(user, pointed_thing)
    local name, meta = init_probe_readonly(user, pointed_thing)
    if not name then return end

    local measure = meta.fields.fuel
    if measure then
        chat_display(name, S("BURN UNITS REMAINING:"), measure)
    else
        chat_data(name, S("NOT MEASURABLE!"))
    end
end


minetest.register_craftitem("artifacts:fuel_probe", {
    description = S("Fuel Probe"),
    inventory_image = "artifacts_fuel_probe.png",
    wield_image = "artifacts_fuel_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        fuel_probe(user, pointed_thing)
    end,
    _dig_tip = S("List fuel units of node")
})

------------------------------------
--SMELTER PROBE
--get smelting progress
------------------------------------

local smelter_probe = function(user, pointed_thing)
    local name, meta, ndef = init_probe_readonly(user, pointed_thing)
    if not name then return end

    local measure = meta.fields.roast
    if ndef.name ~= 'tech:iron_and_slag' or not measure then
        chat_data(name, S("NOT MEASURABLE!"))
    else
        chat_display(name, S("SMELTING UNITS REMAINING:"), measure)
    end
end


minetest.register_craftitem("artifacts:smelter_probe", {
    description = S("Smelter Probe"),
    inventory_image = "artifacts_smelter_probe.png",
    wield_image = "artifacts_smelter_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        smelter_probe(user, pointed_thing)
    end,
    _dig_tip = S("List remaining units of node for smelting"),
})


------------------------------------
--POTTERS PROBE
--get  progress
------------------------------------

local potters_probe = function(user, pointed_thing)
    local name, meta = init_probe_readonly(user, pointed_thing)
    if not name then return end

    local measure = meta.fields.firing or meta.fields.roast
    if measure then
        chat_display(name, S("FIRING UNITS REMAINING:"), measure)
    else
        chat_data(name, S("NOT MEASURABLE!"))
    end
end


minetest.register_craftitem("artifacts:potters_probe", {
    description = S("Potter's Probe"),
    inventory_image = "artifacts_potters_probe.png",
    wield_image = "artifacts_potters_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        potters_probe(user, pointed_thing)
    end,
    _dig_tip = S("List remaining firing units of unfired clay"),
})

------------------------------------
--CHEFS PROBE
--get cooking progress
------------------------------------

local chefs_probe = function(user, pointed_thing)
    local name, meta = init_probe_readonly(user, pointed_thing)
    if not name then return end

    local measure = meta.fields.baking
    if measure then
        chat_display(name, S("COOKING UNITS REMAINING:"), measure)
    else
        chat_data(name, S("NOT MEASURABLE!"))
    end
end


minetest.register_craftitem("artifacts:chefs_probe", {
    description = S("Chef's Probe"),
    inventory_image = "artifacts_chefs_probe.png",
    wield_image = "artifacts_chefs_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        chefs_probe(user, pointed_thing)
    end,
    _dig_tip = S("List remaining cooking units of pointed food")
})
------------------------------------
--ADMINS PROBE
--get node groups
------------------------------------

local admins_probe = function(user, pointed_thing)
    local name, meta, ndef, param2 =
        init_probe(user, pointed_thing)
    if not name then
        return
    end
    local groups = minetest.serialize(ndef.groups)
    groups = groups:gsub("return ", "")
    groups = groups:gsub("{", "")
    groups = groups:gsub("}", "")
    groups = groups:gsub(",", ", ")
    chat_display(name, S("GROUPS:").." ", groups)
end

------------------------------------
--FARMERS PROBE
--get growth progress
------------------------------------

local farmers_probe = function(user, pointed_thing)
    local name, meta, ndef, param2 =
        init_probe_readonly(user, pointed_thing)
    if not name then return end
    local groups = ndef.groups or {}

    local growth = meta.fields.growth
    local health = meta.fields.health
    local fertility = groups.fertility

    local check_plant_type = function()
        if param2 < 64 then
            chat_display(name, S("PLANT TYPE:"), S("Wild"))
            return "wild"
        elseif param2 < 128 then
            chat_display(name, S("PLANT TYPE:"), S("Domesticated"))
            return "dom"
        else
            chat_display(name, S("PLANT TYPE:"), S("Half-wild"))
            return "half"
        end
    end

    local check_growth = function()
        if growth then
            chat_display(name, S("GROWTH UNITS REMAINING:"), growth)
        else
            chat_data(name, S("PLANT GROWTH NOT MEASURABLE!"))
        end
    end

    local check_health = function()
        if health then
            chat_display(name, string.upper(S("Health:")), health)
        else
            chat_data(name, S("PLANT HEALTH NOT MEASURABLE!"))
        end
    end

    if groups.flora or groups.mushroom then
        local plant_type = check_plant_type()
        if plant_type == "dom" or plant_type == "half" then
            check_growth()
            check_health()
        end
    elseif groups.sediment and fertility then
        if groups.wet_sediment == 1 then
            chat_display(name, S("STATE:"), S("wet"))
        elseif groups.wet_sediment == 2 then
            chat_display(name, S("STATE:"), S("salty"))
        else
            chat_display(name, S("STATE:"), S("dry"))
        end
        chat_display(name, S("FERTILITY:"), fertility)
        -- this soil has roots!
        if groups.roots == 1 then
            chat_display(name, S("ROOTS:"), meta.fields.root_nr)
        end
    else
        chat_data(name, S("NOT MEASURABLE: NEEDS A PLANT OR SOIL"))
    end
end


minetest.register_craftitem("artifacts:farmers_probe", {
    description = S("Farmer's Probe"),
    inventory_image = "artifacts_farmers_probe.png",
    wield_image = "artifacts_farmers_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        farmers_probe(user, pointed_thing)
    end,
    _dig_tip = S("List stats of plant or soil")
})



------------------------------------
--ANTIQUORIUM CHISEL
--able to dig granite etc, no good for anything else.
------------------------------------
local chisel = {
    description = S("@1 Chisel", S("Antiquorium")),
    inventory_image = "artifacts_antiquorium_chisel.png",
    tool_capabilities = {
        full_punch_interval = 1.0,
        groupcaps={
            cracky = {times={[1]=6.5, [2]=5.5, [3]=4.50}, uses=600, maxlevel=3},
        },
        damage_groups = {fleshy = 1},
    },
    sound = {breaks = "tech_tool_breaks"},
}
minetest.register_tool("artifacts:antiquorium_chisel", chisel)



------------------------------------
--SPYGLASS
------------------------------------
local spyglass_players = {}
-- uses this to determine which players are looking through a spyglass or not

local function use_spyglass(player)
    local p_name = player:get_player_name()
    local function remove_scope()
        if not player or not minetest.is_player(player) then
            spyglass_players[p_name] = nil
            return
        end
        if type(spyglass_players[p_name]) == "number" then
            player:hud_remove(spyglass_players[p_name])
        end
        spyglass_players[p_name] = nil
        player:set_fov(0, false, .1)
    end
    -- if player is using spyglass while activating then get out of the zoom
    if spyglass_players[p_name] then
        remove_scope()
        return
    end
    -- continue as normal (zoom in)
    spyglass_players[p_name] = player:hud_add({
            name = "spyglass_scope",
            [hud_type] = "image",
            text = "artifacts_scope_hud.png",
            z_index = -500,
            position = {x = 0.5, y = 0.5},
            alignment = {x = 0, y = 0},
            scale = { x = -100, y = -100},
            offset = {x = 0, y = 0}
    })
    minetest.sound_play("artifacts_scope_zoom",{
                            pos = player:get_pos(),
                            pitch = 1 + (math.random(-10,10)/100),
                            gain = 0.9,
                            max_hear_distance = 4,
    })
    player:set_fov(10, false, .4)

    -- utilize this function every 0.5 seconds
    --  to check if the player should be zoomed in or not
    local function verify()
        if not player or not minetest.is_player(player) then
            remove_scope()
            return
        end
        if player:get_wielded_item():get_name() ~= "artifacts:spyglass" then
            remove_scope()
            return
        end
        -- prevent verify from running again by any means necessary
        if player:get_fov() == 0 then
            spyglass_players[p_name] = nil
            return
        end
        if not spyglass_players[p_name] then
            return
        end
        -- still using the spyglass
        minetest.after(0.5, verify)
    end
    verify()

end


--  item
local spyglass_def = {
    description = S("Spyglass"),
    inventory_image = "artifacts_spyglass.png",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        use_spyglass(user)
    end,
    _dig_tip = S("View far distances"),
    _on_use_item = function(user, itemstacked, pointed_thing)
        use_spyglass(user)
    end,
    _use_tip = S("View far distances"),
    -- right clicking
    on_place = function(itemstack, placer, pointed_thing)
        local on_click = minimal.on_rightclick(itemstack, placer, pointed_thing)
        if on_click ~= false then
            return on_click
        end
        use_spyglass(placer)
    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        use_spyglass(user)
    end,
    _place_tip = S("View far distances"),
}
minetest.register_craftitem("artifacts:spyglass", spyglass_def)


------------------------------------
--ANIMAL PROBE
--get condition of an animal
------------------------------------

local animal_probe = function(user, pointed_thing)
    local name = user:get_player_name()
    -- permit getting stats of eggs
    local pos = pointed_thing.type == "node" and pointed_thing.under
    if pos then
        local nodedef = minimal.get_nodedef(pos)
        -- not a node, has no groups, or isn't an egg
        if not (nodedef and nodedef.groups and nodedef.groups.egg) then return end
        local timer = minetest.get_node_timer(pos)
        local timeout = timer:get_timeout()
        local gest_perc = timeout ~= 0 and math.floor((timer:get_elapsed()/timeout)*100)
        local egg_str = gest_perc and S("Gestation: @1%", gest_perc) or S("EGG IS DEAD")
        -- now to send the info!
        chat_display(name, S("@1 CONDITION:", S("EGG")), egg_str)
        return
    -- not pointing at an entity, return
    elseif pointed_thing.type ~= "object" then return end
    -- getting info of the entity
    local pt_ref = pointed_thing.ref
    if minetest.is_player(pt_ref) then
        local pt_meta = pt_ref:get_meta()
        -- index 1 is years, index 2 is days
        local age = {
            0, -- filling out first index for years
            -- seconds survived
            math.floor((pt_meta:get_int("char_time_survived") or 0)/1200), -- days (divided by 1200sec to get days)
        }
        -- numbered indexes used for proper table.concat functionality
        age[1] = math.floor(age[2] / 80) -- years
        age[2] = age[2] - (80 * age[1]) -- modified to look clean (days after the specified year)
        age[1] = age[1] == 1 and S("1 year old") or S("@1 years old", tostring(age[1]))
        age[2] = age[2] == 1 and S("1 day old") or S("@1 days old", tostring(age[2]))
        age = table.concat(age, ", ") -- adds comma after years but not after days
        local stats = {
            S("Health: @1", S("@1 units",tostring(pt_ref:get_hp()))), -- e.g: Health: 20 units
            S("Age: @1", age), -- e.g: 2 years old, 45 days old
            S("Energy: @1%", -- e.g: Energy: 56.9%
                tostring(pt_meta:get_int('energy')/10)), -- out of 1000, divide by 10 to get percentage
            S("Body Temp: @1", -- e.g: 37C
                climate.get_temp_string(pt_meta:get_int('temperature'),pt_meta)), -- use command to get in F, C, or K
            S("Hunger: @1%", -- e.g: 87.5%
                tostring(pt_meta:get_int('hunger')/10)), -- ditto energy
            S("Thirst: @1%", -- e.g: 98%
                tostring(pt_meta:get_int('thirst'))), -- already proper percentage
            S("Effects: @1",
                tostring(pt_meta:get_int('effects_num'))) -- number of diseases
        }
        local p_name = S("SELF") -- default to self if singleplayer
        -- get player name if multiplayer
        if not minetest.is_singleplayer() then
            p_name = pt_ref:get_player_name()
        end
        -- now to send the info!
        chat_display(name, S("@1 CONDITION:",p_name), table.concat(stats, "    "))
    else
        local ent = pt_ref:get_luaentity()
        -- not a valid entity or doesn't have memory
        if not (ent and ent.memory) then
            return
        end
        local r_ent_hp = ent.hp
        local r_ent_e = mobkit.recall(ent,'energy')
        local r_ent_a = mobkit.recall(ent,'age')
        -- no energy, age, or HP
        if not (r_ent_e and r_ent_a and r_ent_hp) then
            return
        end
        r_ent_e = math.floor(r_ent_e)
        r_ent_a = math.floor(r_ent_a)
        local stats = {
            S("Health: @1", S("@1 units", tostring(r_ent_hp))),
            S("Age: @1", S("@1 seconds", tostring(r_ent_a))),
            S("Energy: @1", S("@1 units", tostring(r_ent_e)))
        }
        -- optional variables
        -- oxygen percentage
        local r_ent_oxy = ent.oxygen
        local r_ent_lung = ent.lung_capacity
        if r_ent_oxy and r_ent_lung then
            -- permit 2 decimal points, divide by 100 to ensure it's a proper percentage
            stats[#stats + 1] = math.ceil((r_ent_oxy/r_ent_lung)*10000)/100
            -- convert to oxygen percentage string (e.g: Oxygen: 67.53%)
            stats[#stats] = S("Oxygen: @1%", tostring(stats[#stats]))
        end
        -- if female, add whether or not we're pregnant
        local r_ent_sex = ent.sex
        if r_ent_sex == "female" then
            local preg = mobkit.recall(ent,"pregnant") or false
            preg = preg and S("Yes") or S("No")
            stats[#stats + 1] = S("Pregnant: @1", preg)
        end
        -- now to send the info!
        chat_display(name, S("@1 CONDITION:", S("ANIMAL")), 
            table.concat(stats, "    "))
    end
end


minetest.register_craftitem("artifacts:animal_probe", {
    description = S("Animal Probe"),
    inventory_image = "artifacts_animal_probe.png",
    wield_image = "artifacts_animal_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        animal_probe(user, pointed_thing)
    end,
    _dig_tip = S("List stats of pointed animal or player"),
    -- probe self
    _on_use_item = function(user, itemstack, pointed_thing)
        -- let's play doctor doctor
        animal_probe(user, {ref = user, type = "object"})
    end,
    _use_tip = S("Inspect self")
})

-- Group probe (only for developers)
minetest.register_craftitem("artifacts:admins_probe", {
    description = S("Admin's Probe"),
    inventory_image = "artifacts_admins_probe.png",
    wield_image = "artifacts_admins_probe.png^[transformR90",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if minimal.item_pickup(user, pointed_thing) then
            return
        end
        admins_probe(user, pointed_thing)
    end,
    _dig_tip = S("List groups of pointed node")
})
