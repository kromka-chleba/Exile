-- fermentation.lua
------------------------------------
--FERMENTATION FUNCTIONALITY
-----------------------------------
-- Internationalization
local S = ncrafting.S
-- misc functions + globals
local random = math.random
climate = climate
ncrafting = ncrafting

-- BASIC FUNCTIONALITIES

ncrafting.ferment_interval = 5

function ncrafting.get_ferment_data(name)
    if type(name) == "userdata" and type(name["get_name"]) == "function" then
        name = name:get_name()
    elseif type(name) == "table" then
        if name.x and name.y and name.z then
            name = minetest.get_node(name)
        end
        name = name.name
    end
    if type(name) ~= "string" then return end
    local def = minetest.registered_nodes[name]
    if not def then return end
    local ferment_data = {
        to = def._ferment_to,
        time = def._ferment_time or {min=300,max=360},
        temp_range = def._ferment_temp_range,
    }
    if type(def._ferment_aerobic) == "boolean" then
        -- aerobic: true if need air, false if needs no air
        --   nil if it doesn't matter
        ferment_data.aerobic = def._ferment_aerobic
    end
    return ferment_data
end

-- find ferment or create a ferment meta
function ncrafting.get_or_create_ferment(name,meta)
    -- prefer getting our info from a table, ideally fields
    -- if not, get_int from a meta
    local ferment = type(meta) == "table" and (type(meta.fields) == "table" and meta.fields.ferment or meta.ferment) or
      minimal.is_meta(meta) and meta:get_int("ferment")
    -- tonumber what we got, otherwise do 0 (call tonumber if ferment was something)
    ferment = ferment and tonumber(ferment) or 0 -- sometimes they can be string
    if ferment == 0 then
        -- base ferment is 300,360
        local ferment_data = ncrafting.get_ferment_data(name)
        if not ferment_data then return random(300,360) end
        -- use a singular type of number for randomization
        ferment = type(ferment_data.time) == "number" and ferment_data.time
            -- permit randomization if min and max provided
            or type(ferment_data.time) == "table"
            and random(ferment_data.time.min,ferment_data.time.max)
            -- couldn't get a proper time, do base ferment randomization
            or random(300,360)
    end
    return ferment
end

-- transfer meta from stack to node
-- permit stack data (to_table of stack meta or is stack meta) and node meta arguments (nmeta, sdata)
function ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing, nmeta, sdata)
    nmeta = nmeta or core.get_meta(pos)
    -- not an adequate stack data table
    if type(sdata) ~= "table" or not sdata.fields then
        sdata = minimal.is_meta(sdata) and sdata or itemstack:get_meta()
        sdata = sdata:to_table() or {}
    end
    sdata = sdata.fields or sdata -- prefer fields
    -- create ferment if none, update node meta
    sdata.ferment = sdata.ferment or ncrafting.get_or_create_ferment(itemstack)
    nmeta:from_table({fields=sdata})
end

function ncrafting.ferment_on_construct(pos)
    --duration of ferment
    local meta = minetest.get_meta(pos)
    meta:set_int("ferment", ncrafting.get_or_create_ferment(pos))
    --ferment
    minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
end

-- custom function that preserves metadata from a replaced node to an itemstack

-- luanti engine confusingly has meta fields be 'oldmeta'
-- which I didn't realize until way after making this function - TPH
function ncrafting.ferment_preserve_metadata(pos, oldnode, oldmeta,
                                             transferred_stack, imeta)
    imeta = imeta or transferred_stack:get_meta()
    -- oldmeta will be fields, if not, it's probably an actual meta (as per old usage)
    if type(oldmeta) ~= "table" then
        oldmeta = minimal.is_meta(oldmeta) and oldmeta -- if meta
        oldmeta = oldmeta and oldmeta:to_table() -- to_table() can return nil sometimes
        oldmeta = oldmeta or {} -- create an empty table on failure
    end
    oldmeta = oldmeta.fields or oldmeta -- prefer fields
    oldmeta.ferment = oldmeta.ferment or ncrafting.get_or_create_ferment(transferred_stack)
    imeta:from_table({fields=oldmeta})
end

function ncrafting.ferment_on_timer(pos, elapsed)
    local ferment_data = ncrafting.get_ferment_data(pos)
    if not ferment_data then return false end
    local temp_range = ferment_data.temp_range
    local aerobic = ferment_data.aerobic
    if temp_range then
        --ferment if at right temp
        local temp = climate.get_point_temp(pos)
        if temp <= temp_range.min or temp >= temp_range.max then
            -- loop again if conditions not right
            return true
        end
    end
    if type(aerobic) == "boolean" then
        local air_node = minetest.registered_nodes[
            minetest.get_node(minimal.shift_pos(pos,{y=1})).name]
        if air_node.drawtype == "airlike" then
            -- anaerobic and air is above...
            if not aerobic then
                return true
            end
        elseif aerobic then
            -- aerobic, but no air above...
            return true
        end
    end
    -- only access meta if can ferment
    local meta = minetest.get_meta(pos)
    local ferment = meta:get_int("ferment")
    -- catchup included
    ferment = ferment -
        (elapsed >= (ncrafting.ferment_interval*2)
         and math.floor(elapsed/ncrafting.ferment_interval) or 1)
    if ferment <= 1 then -- prevent possibility of refreshed fermenting at 0
        local swap_def = minetest.registered_nodes[ferment_data.to]
        minetest.swap_node(pos, {name = ferment_data.to})
        minetest.get_meta(pos):set_int("ferment",0) -- end fermentation
        if type(swap_def.on_construct) == "function" then
            -- run on_construct function if available
            swap_def.on_construct(pos)
        end
        return false
    else
        meta:set_int("ferment",ferment)
    end
    return true
end

-- bread unique
-------------------------------------------------------------------

-- TODO: better system for fermentation + baking mechanics
-- returns function to set on_timer with
--[[ WARNING: DON'T add custom paramters to "on_timer" luanti function,
-- luanti may use it later (like in 5.14, where we pass
-- from on_timer (pos, elpased)
-- to on_timer (pos, elapsed, node, timeout))
--]]
function ncrafting.dough_get_on_timer(chance)
    chance = chance or 0.01 -- provided chance or 1%
    -- provide function return to run
    return function(pos, elapsed)
        local node = core.get_node(pos)
        local meta = core.get_meta(pos)
        -- unleavened bread baking mechanics
        local baking_data = HEALTH.bake_table[node.name] -- check if we can bake
        local temp -- declare here to reuse in later if statement
        if baking_data then
            temp = climate.get_point_temp(pos)
            -- we're actually cooking! (natural temps can't go over 70 anyways)
            if temp >= 70 then
                if not meta:contains("baking") then
                    -- remove any fermentation
                    local metat = meta:to_table() or {}
                    -- and add baking int to the cleared fields
                    metat.fields = {baking = baking_data.time}
                    meta:from_table(metat)
                    -- reset timer to be cooking
                    core.get_node_timer(pos):start(ncrafting.cook_rate)
                    return false
                end
            end
        end
        -- WE BAKING!! (if we can bake)
        if baking_data and meta:contains("baking") then
            return ncrafting.do_bake(pos, elapsed,
                                 baking_data.temp, baking_data.time,
                                 baking_data.cooked, baking_data.burned)
        end

        if meta:get_int("ferment") ~= 0 then -- we're fermentin'
            -- we're done fermenting!
            if not ncrafting.ferment_on_timer(pos, elapsed) then
                node = core.get_node(pos) -- we're a new node now
                local metat = meta:to_table()
                metat.fields = {}
                -- set baking data if we're a bakeable
                baking_data = HEALTH.bake_table[node.name]
                if baking_data then
                  metat.fields.baking = baking_data.time
                end
                meta:from_table(metat)
                node.param2 = 1 -- set param2 to 1 for "fresh batch"
                core.swap_node(pos,node)
                return false
            end
            -- otherwise continue fermenting
            return true
        -- let's try fermenting
        elseif math.random() <= chance then
            -- check for temp_range first before trying to ferment
            local nodedef = minetest.registered_nodes[node.name]
            local temp_range = nodedef._ferment_temp_range
            if temp_range then
                local temp = temp or climate.get_point_temp(pos)
                if temp <= temp_range.min or temp >= temp_range.max then
                    -- loop again if conditions not right
                    return true
                end
            end
            -- chance and temp successful, ferment!
            ncrafting.ferment_on_construct(pos)
            return false
        end
        -- check again later (40sec to 85sec)
        core.get_node_timer(pos):start(math.random(40,85))
        return false
    end
end

function ncrafting.dough_infection(player, pos, nodedef, itemstack, idef)
    idef = idef or itemstack and itemstack:get_definition()
    if not (idef and idef.groups and idef.groups.infect_dough) then return end
    local meta = core.get_meta(pos)
    if meta:contains("ferment") then return end -- already infected
    -- successful infection
    ncrafting.ferment_on_construct(pos)
    return true
end

-- dough placement functions
function ncrafting.dough_preserve_metadata(pos, oldnode, oldmeta, drops, imeta)
    oldmeta = oldmeta or {} -- purify
    if not oldmeta.ferment then return end -- not fermenting
    oldmeta.baking = nil -- remove baking value
    -- set description if not set
    oldmeta.description = oldmeta.description or S("Fermenting @1",drops[1]:get_description())
    ncrafting.ferment_preserve_metadata(pos, oldnode, oldmeta, drops[1], imeta)
end

function ncrafting.dough_after_place_node(pos, placer, itemstack, pointed_thing, nmeta, imeta)
    local sdata = imeta or itemstack:get_meta()
    sdata = sdata:to_table() or {fields={}}
    -- not fermenting, return
    if not sdata.fields.ferment then return end
    -- we're fermenting, run ferment after_place
    ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing, nmeta, sdata)
end

-- fermented dough functionality

function ncrafting.dough_fermented_preserve_metadata(pos, oldnode, oldmeta, drops)
    -- can't get yeast from this, not a fresh batch
    if not oldnode then return end
    if oldnode.param2 ~= 1 then return end
    local nodedef = minetest.registered_nodes[oldnode.name]
    local get_microbes = nodedef.breads_get_microbes or
      function()
          return math.random(1,3)
      end
    -- get fresh batch catchable microbes
    local microbes = get_microbes(pos, oldnode, nodedef)
    if not microbes then return end
    microbes = type(microbes) ~= "table" and {microbes}
    for _,item in ipairs(microbes) do
        if type(item) == "number" then
            item = "tech:yeast_dough "..item
        end
        if type(item) == "string" then
            drops[#drops + 1] = item
        end
    end
end
