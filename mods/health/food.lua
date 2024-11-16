--food.lua
--handles the intake of food and drink

--Modding info:
--[[
    To add new foods, define your node(s), then pass a table with food info to
    exile_add_food_hook(name,table). Its _on_use_item will be set automatically.
    Make sure all your nodes have been defined BEFORE you send any tables!
    exile_add_food_hook() will override a node's _on_use_item.

    For cookable things, define the node, and a name_cooked/name_burned version,
    then pass the cooking data to HEALTH.add_bake(table). Don't forget to add the
    cooked version to the food table.
    If the burned version is not also added to foods, it will be inedible.
    HEALTH.add_bake() will override a node's on_construct and on_timer.

    If a food can only be cooked in a pot, don't define a name_cooked node,
    but add it to the food table anyway. The cooking pot will make a soup using
    the food table's data, but the food will not be able to bake in an oven or
    over a fire.
    #TODO: Test this ^^ after the cooking pot supports both tables
]]--

HEALTH = HEALTH

-- Internationalization
local S = HEALTH.S

dofile(minetest.get_modpath('health')..'/data_food.lua')

-- Declare globals
local food_harm_table = HEALTH.harm_table
local food_cure_table = HEALTH.cure_table
local food_table = HEALTH.food_table
local bake_table = HEALTH.bake_table

-- used to get health effect data for food_harm and food_cure
-- returns table with effect tables with their name
--   ('tg'), severity ('sv'), and chance ('ch') listed
-- thusly sterilizing any issues and conforming them for better use
local function get_health_effect_data(datat,name)
    -- datatable (harm_table or cure_table), name/item
    name = type(name) == "string" and name
        or type(name) == "userdata" and type(name["get_name"]) == "function"
        and name:get_name()
        or nil
    local hed = datat[name] -- [h]ealth [e]ffect [d]ata
    if not hed then return end
    if #hed == 0 then return end -- no data/effects
    local g_ch = hed.ch
        or hed.chance -- "global" chance (for all noted effects in table)
    local g_sv = hed.sv
        or hed.severity -- "global" severity (ditto /\)
    -- to be returned \/
    local effects = {}
    -- look through hed
    for ind,eff in pairs(hed) do -- for effect tables
        -- accept function arguments for HEDs
        if type(eff) == "function" then
            eff = eff() -- must be table return
        end
        if type(eff) == "table" and type(ind) == "number" then
            -- do not conflict with above "globals"

            -- chance (assume default of 0.001)
            local ch = eff.ch or eff.chance or g_ch or 0.001
            -- provide chance in case someone wishes to modify the chance after the fact
            -- severity (assume default of 1)
            local sv = eff.sv or eff.severity or g_sv or 1
            if type(sv) == "table" then
                -- is a chance, decide what severity it should be
                sv = math.random(sv[1],sv[2])
            end
            -- integers only
            sv = math.floor(sv)
            -- health effect tag (string or table, is made into table for conformity)
            local tg = type(eff.tags) == "string" and {eff.tags}
                or type(eff.tags) == "table" and eff.tags or nil
            -- table allows for you to specify numerous health effects
            --   with the same severity or chance
            if tg then
                for _,tg_name in pairs(tg) do
                    if type(tg_name) == "string" then
                        -- only strings allowed
                        effects[#effects + 1] = {tg=tg_name,sv=sv,ch=ch}
                    end
                end
            end
        end
    end
    if #effects <= 0 then
        -- nothing to do! don't do anythin'!
        return
    end
    return effects
end

local function do_food_harm(user, name)
    local effects = get_health_effect_data(food_harm_table,name)
    if not effects then return end -- got nothin'
    -- iterate through effects and add upon chance
    for _,effect in pairs(effects) do
        if math.random() <= effect.ch then
            HEALTH.add_new_effect(user, {effect.tg, effect.sv})
        end
    end
end

-- does the reverse of do_food_harm, curing stuff instead :D
local function do_food_cure(user, name)
    local effects = get_health_effect_data(food_cure_table,name)
    if not effects then return end -- got nothin'
    -- iterate through effects and remove from player
    for _,effect in pairs(effects) do
        if math.random() <= effect.ch then
            HEALTH.remove_new_effect(user, {effect.tg, effect.sv})
        end
    end
end


function HEALTH.eatdrink_playermade(itemstack, user, pointed_thing)
    local imeta = itemstack:get_meta()
    local pname = user:get_player_name()
    local t = minetest.deserialize(imeta:get_string("eat_value"))
    if t == nil then minetest.log("warning", pname..
                                  " ate an invalid food of type "..
                                  itemstack:get_name())
        return
    end
    -- check for any extra stuff we should add to this playermade
    -- used for soups/stews to get proper returned empty + sound
    local extra_stats = HEALTH.get_food_stats(itemstack)
    if extra_stats then
        for ind,val in pairs(extra_stats) do
            if type(val) == "number" then
                -- add any custom stuff
                t[ind] = val + (t[ind] or 0)
            -- otherwise overwrite
            else
                t[ind] = val
            end
        end
    end
    return HEALTH.use_item(itemstack, user, t)
end

-- helps to get direct proper value naming or 0 for each
function HEALTH.get_food_stats(name,prefercooked)
    if type(name) == "userdata" and type(name["get_name"]) == "function" then
        name = name:get_name()
    end
    local ft = type(name) == "table" and name or -- food_table
        (prefercooked and type(name) == "string" and food_table[name.."_cooked"])
        or food_table[name]
    if type(ft) ~= "table" then
        return
    end
    local stats = {}
    -- numbered indexes for legacy support
    stats.hp = ft.hp or ft.health or ft[1] or 0
    stats.th = ft.th or ft.thirst or ft[2] or 0
    stats.hu = ft.hu or ft.hun or ft.hunger or ft[3] or 0
    stats.en = ft.en or ft.energy or ft[4] or 0
    stats.temp = ft.temp or ft.temperature or ft[5] or 0
    stats.rwi = ft.replace_item or ft.replace_with_item or ft.rwi or ft[6] or ""
    stats.sound = ft.eat_sound or ft.sound or ft.es or "health_eat"
    if type(stats.sound) == "string" then
        stats.sound = {name=stats.sound, max_hear_distance = 3, gain = 0.25}
    end
    return stats
end

function HEALTH.eatdrink(itemstack, user, pointed_thing)
    local name = type(itemstack) == "string" and itemstack
        or itemstack:get_name()

    if minetest.registered_aliases[name] then
        name = minetest.registered_aliases[name]
    end
    if not food_table[name] then
        minetest.chat_send_player(user:get_player_name(),
                                  S("This is inedible."))
        return
    end
    do_food_harm(user, name)
    do_food_cure(user, name)
    local t = food_table[name]
    return HEALTH.use_item(itemstack, user, t)
end

local function bake_error(pos, selfname)
    local posstr = minetest.pos_to_string(pos)
    minetest.log("error", "Warning, attempting to use a bake timer at "..
                 "pos: "..posstr..", set on a non-bakeable node:"..selfname)
end

-- Add baking properties to the raw and cooked variants
-- overrides on_construct and on_timer
local function setup_bakeable(name,bake_info)
    local raw = minetest.registered_nodes[name]
    local cooked = minetest.registered_nodes[bake_info.cooked]
    if not (raw and cooked) then
        -- causes issues with sea_lettuce if not commented out
        --error(name..": missing nodes for baking (raw or cooked variant not found)")
        return
    end
    local function check_error(pos)
        if not bake_table[name] then
            bake_error(pos, name)
            return true
        end
    end
    local function on_construct(pos)
        if check_error(pos,name) then return true end
        ncrafting.start_bake(pos, bake_info.time)
    end
    local function on_timer(pos, elapsed)
        if check_error(pos,name) then return end
        return ncrafting.do_bake(pos, elapsed,
                                 bake_info.temp, bake_info.time,
                                 bake_info.cooked, bake_info.burned)
    end
    -- permit usage of regular node on_construct/on_timer
    -- raw can cook
    minetest.override_item(name,{
        on_construct = raw.on_construct or on_construct,
        on_timer = raw.on_timer or on_timer
    })
    -- cooked can burn
    minetest.override_item(cooked.name,{
        on_construct = cooked.on_construct or on_construct,
        on_timer = cooked.on_timer or on_timer
    })
end

-- only accepts 1 node at a time for baking definition
-- Adds bakeables, mod must send a string and table in the following format:
-- name (nodedef name),{temp,time}
function HEALTH.add_bake(name,data)
    -- provide errors with helpful information
    if type(name) ~= "string" then
        error(debug.traceback(
                  "name provided for bake data is not a string, got '"..
                  type(name).."'",2))
    elseif type(data) ~= "table" then
        error(debug.traceback(name..": bake data is not a table, got '"..
                              type(data).."'",2))
    end
    if not minetest.registered_nodes[name] then
        error(
            debug.traceback(
                name..": does not exist as a node, cannot add bake data!",2))
    end
    local temp = data.temp or data.temperature
    local time = data.time or data.duration
    if type(temp) ~= "number" then
        error(
            debug.traceback(
                name..": temp provided for bake data is not a number, got '"..
                type(temp).."'",2))
    elseif type(time) ~= "number" then
        error(debug.traceback(
                  name..": time provided for bake data is not a number, got '"
                  ..type(time).."'",2))
    end
    local bake_info = {temp=temp, time=time}
    bake_info.cooked = type(data.cooked) == "string" and data.cooked
        or name.."_cooked"
    bake_info.burned = type(data.burned) == "string" and data.burned
        or name.."_burned"
    setup_bakeable(name,bake_info)
    bake_table[name] = bake_info
    minetest.log("info","Bake data successfully added for "..name)
    return bake_table[name]
end

-- FOOD HARM AND FOOD CURE SHOULD BE DEFINED AS SO:
--[[
    name (string),food_data (table)

    food_data is to contain "effect" tables with defined "tags" to run
    food_data can include a "global" chance and severity to fill in for missing values in the effect tables as so:
    {ch/chance=0.5,sv/severity=1,...}

    an "effect" table should consist of the following:
    {tg/tag/tgs/tags="Health Effect Name"}
    with option to specify local chance and severity
    {ch/chance = 0.1, sv/severity=2,... (tags table)}
    or as so:
    {ch=0.1,sv=2,tg="Health Effect Name"}
    tags value can be a table for multiple effects to occur or be cured according to the effect table
    {tg/tag/tgs/tags={"Health Effect1", "Health Effect2", "Health Effect3"}

    An example of a proper local effect table using the above options would look like this:
    {ch=0.6,sv=2,tg={"Hepatotoxicity","Food Poisoning"}}

    An example of a proper food_data table with 'global' severity and local effect tables may look like this:
    {sv=2,
    {ch=0.9,tg="Food Poisoning"},
    {ch=0.3,tgs={"Neurotoxicity","Hepatotoxicity"}},
    }
    == if a "global" chance/severity exists, it will NOT override
    any locally defined chance/severity in a local effect table

    SPECIALTY: an "effect table" can also be a function, for as long as the function returns a proper effect table
]]--

-- only accepts 1 item at a time for harm definition
-- Adds harmful effects to occur upon the consumption of the named item
function HEALTH.add_harm(name,data)
    -- provide errors with helpful information
    if type(name) ~= "string" then
        error(
            debug.traceback("name provided for harm data is not a string, got '"..
                            type(name).."'",2))
    elseif type(data) ~= "table" then
        error(debug.traceback(
                  name..": harm data is not a table, got '"..type(data).."'",2))
    end
    local g_ch = data.ch or data.chance
    local g_sv = data.sv or data.severity
    if g_ch and type(g_ch) ~= "number" then
        error(
            debug.traceback(
                name..": chance value for harm data is not a number or nil, got '"..
                type(g_ch).."'",2))
    elseif g_sv and type(g_sv) ~= "number" then
        error(
            debug.traceback(
                name..": severity value for harm data is not a number or nil, got '"
                ..type(g_sv).."'",2))
    end
    for ind,eff in pairs(data) do -- index, effect
        if type(ind) == "number" and type(eff) == "table" then
            local ch = eff.ch or eff.chance
            local sv = eff.sv or eff.severity
            ch = type(ch) == "number" and ch or nil
            sv = type(sv) == "number" and sv or nil
            local tg = eff.tg or eff.tag or eff.tgs or eff.tags
            tg = type(tg) == "string" and {tg}
                or type(tg) == "table" and tg or nil
            local efferr = name..": effect table of index "..ind
            -- effect error message
            if not tg then
                error(
                    debug.traceback(
                        efferr.." does not have a health effect tag to apply with",2))
            elseif not (g_ch or ch) then
                minetest.log(
                    "warning",efferr..
                    " does not have a chance value assigned, default to 0.001")
                data.ch = 0.001
            elseif not (g_sv or sv) then
                minetest.log(
                    "warning",efferr..
                    " does not have a severity value assigned, default to 1")
                data.sv = 1
            end
            eff.tags = tg
        end
    end
    food_harm_table[name] = data
    minetest.log("info","Food harm data successfully added for "..name)
    return data
end

-- only accepts 1 item at a time for harm definition
-- Add efects that should be cured upon the consumption of the named item
function HEALTH.add_cure(name,data)
    -- provide errors with helpful information
    if type(name) ~= "string" then
        error(debug.traceback(
                  "name provided for food cure data is not a string, got '"..
                  type(name).."'",2))
    elseif type(data) ~= "table" then
        error(debug.traceback(name..": food cure data is not a table, got '"..
                              type(data).."'",2))
    end
    local g_ch = data.ch or data.chance
    local g_sv = data.sv or data.severity
    if g_ch and type(g_ch) ~= "number" then
        error(
            debug.traceback(
                name..
                ": chance value for food cure data is not a number or nil, got '"..
                type(g_ch).."'",2))
    elseif g_sv and type(g_sv) ~= "number" then
        error(
            debug.traceback(
                name..": severity value for food cure data is not a number or nil, got '"..
                type(g_sv).."'",2))
    end
    for ind,eff in pairs(data) do -- index, effect
        if type(ind) == "number" and type(eff) == "table" then
            local ch = eff.ch or eff.chance
            local sv = eff.sv or eff.severity
            ch = type(ch) == "number" and ch or nil
            sv = type(sv) == "number" and sv or nil
            local tg = eff.tg or eff.tag or eff.tgs or eff.tags
            tg = type(tg) == "string" and {tg} or type(tg) == "table" and tg or nil
            local efferr =
                name..": cure effect table of index "..ind -- effect error message
            if not tg then
                error(debug.traceback(
                          efferr..
                          " does not have a health effect tag to apply with",2))
            elseif not (g_ch or ch) then
                minetest.log(
                    "warning", efferr..
                    " does not have a chance value assigned, default to 0.001")
                data.ch = 0.001
            elseif not (g_sv or sv) then
                minetest.log(
                    "warning",efferr..
                    " does not have a severity value assigned, default to 1")
                data.sv = 1
            end
            eff.tags = tg
        end
    end
    food_cure_table[name] = data
    minetest.log("info","Food cure data successfully added for "..name)
    return data
end

function HEALTH.add_food_table(name,data)
    if type(name) ~= "string" then
        error(debug.traceback(
                  "name provided for food table data is not a string, got '"..
                  type(name).."'",2))
    elseif type(data) ~= "table" then
        error(debug.traceback(
                  name..": food table data is not a table, got '"..
                  type(data).."'",2))
    end
    for index,value in pairs(data) do
        if type(index) == "number" then
            -- numbers unsupported
            data[index] = nil
        elseif type(index) == "string" then
            -- lowercase all indexes
            local revised_index = string.lower(index)
            if index ~= revised_index then
                data[revised_index] = value
                data[index] = nil
            end
        end
    end
    local data_length = 0
    -- permit defining harm, cure, and bake definitions
    if type(data.harm) == "table" then
        HEALTH.add_harm(name,data.harm)
        data_length = data_length + 1
    end
    if type(data.cure) == "table" then
        HEALTH.add_cure(name,data.cure)
        data_length = data_length + 1
    end
    if type(data.bake) == "table" then
        HEALTH.add_bake(name,data.bake)
        data_length = data_length + 1
    end
    -- get raw important stats
    local stat_string = ""
    local food_stats = HEALTH.get_food_stats(data)
    -- accepts table values as well as its usual string
    for index,value in pairs(food_stats) do
        -- remove unimportant/'nil' values from data
        if index == "rwi" and value == "" then
            food_stats[index] = nil
        elseif index == "sound" and value == "health_eat" then
            food_stats[index] = nil
        elseif value == 0 then
            food_stats[index] = nil
        elseif type(value) == "number" or type(value) == "string" then
            -- success! at adding values
            data_length = data_length + 1
            stat_string = index..":"..value.."  "
        end
    end
    -- verify if data is important enough to add
    if data_length > 0 then
        -- sufficient data made
        food_table[name] = food_stats
        minetest.log("info","Successfully added food stats for "..
                     name.."; "..stat_string)
        return food_stats
    end
    minetest.log("warning","Insufficient data given for "..
                 name.."'s edible table! Not registering food stats")
end

function HEALTH.add_food_hooks(name,info)
    -- Adds hooks for edible foods, as well as bakeable things
    if type(info) == "table" then
        if not HEALTH.add_food_table(name,info) then
            error()
            return
        end
    end
    local def = minetest.registered_items[name]
    if not def then
        return -- only def related code ahead, return if no def found
    end
    local groups = def.groups or {}
    if food_table[name] and not groups.edible then
        if name:split(":")[1] ~= "nodes_nature" then -- cuz plant api is awful

            minetest.log("warning",
                         "No edible group set for "..name..", patching")
        end
        groups.edible = 1
        minetest.override_item(name, {
                                   _use_tip = S("Eat"),
                                   groups = groups
        })
    end
    if groups.edible then
        -- add consumption _use_tip
        if groups.edible and not def._use_tip then
            minetest.override_item(name,{
                                       _use_tip = S("Eat")
            })
        end
        if not def._on_use_item then
            minetest.override_item(
                name,{
                    _on_use_item = function(player, itemstack, pointed_thing)
                        core.after(0.1, crafting.refresh_recipes_FS, player) -- #TODO is that dirty to refresh crafting formspec in HEALTH mod ?
                        return itemstack:get_definition()._on_consume(player,
                                                                      itemstack,
                                                                      pointed_thing)
                    end,
            })
        end
        if type(def._on_consume) ~= "function" then
            local preferred_eat = groups.edible == 1 and HEALTH.eatdrink
                or groups.edible == 2 and HEALTH.eatdrink_playermade
            minetest.override_item(
                name,{
                    _on_consume = function(player, itemstack, pointed_thing)
                        return preferred_eat(itemstack, player, pointed_thing)
                    end
            })
        end
    end
    if minetest.registered_nodes[name] then
        local bake_info = bake_table[name]
        if bake_info then
            -- ensure "cooked" and "burned" variants
            if not bake_info.cooked then
                bake_info.cooked = name.."_cooked"
            end
            if not bake_info.burned then
                bake_info.burned = name.."_burned"
            end
            setup_bakeable(name,bake_info)
        end
    end
end

-- Add food hooks to all items in edible group or in food tables
minetest.register_on_mods_loaded(function()
        for name,def in pairs(minetest.registered_items) do
            if (def.groups and def.groups.edible)
                or food_table[name]
                or bake_table[name]
                or food_harm_table[name]
                or food_cure_table[name] then

                HEALTH.add_food_hooks(name)
            end
        end
        -- Finalized table list
        -- Outputs a compiled list of all added foods to the minetest log, info level
        -- Run 1 second after mods registered + food hooks added
        minetest.after(
            1, function()
                minetest.log("info", "Finalized list of food_table entries:")
                for name,_ in pairs(food_table) do
                    minetest.log("info",name)
                end
                minetest.log("info","-------")
                minetest.log("info", "Finalized list of bake_table entries:")
                for name,_ in pairs(bake_table) do
                    if not minetest.registered_nodes[name] then
                        minetest.log("info",
                                     "Bake table contains an undefined node: "..name)
                    elseif minetest.registered_nodes[name.."_cooked"] then
                        minetest.log("info",name.."_cooked")
                    else
                        minetest.log("info",
                                     "undefined node (cooking pot only entry): "..
                                     name.."_cooked")
                    end
                    minetest.log("info","-------")
                end
        end)
end)
