-- stage.lua -------------------------------------------------------------

-- Tracks the player's progress through the stages of the tutorial
--  Allows players to die and go back to the start of a stage, or exit/enter

local stage = {} -- namespace
HEALTH = HEALTH
player_api = player_api

local modpath = minetest.get_modpath("tutorial_exile")

stage.handlers = {} -- functions to handle a stage when server is restarted
-- A list, each takes (stage, player, name, instance) arguments like entry/exit
local stages = loadfile(modpath..'/data_stages.lua')(stage)

local mstore = minetest.get_mod_storage()

local tutorial_version = 1

-- Loading/unloading areas -----------------------------------------------

local delay = 7 -- number of seconds to wait before loading next stage

local i_num = {} -- [playername ] = [tutorial_instance_number]
local instance = {} -- track instance contents, to repurpose them. contains:
--[[a= {
    [instance_num] = {
    number = 1, this instance's number,
    in_use = false,
    active = 0, -- last active stage #
    ready = 0, -- counts up when a stage has finished loading
    offset = vector.new(), -- cached offset
    }
    }]]--



-- Save/load instance table via mod storage
-- load_all_instances

local reloading = false
local tutorial_version_stored = tonumber(mstore:get("tutorial_exile_version"))
if not tutorial_version_stored
    or tutorial_version_stored < tutorial_version then
    print("RELOADING TUTORIAL STAGES, VERSION ",tutorial_version,
          " vs ",tutorial_version_stored)
    reloading = true -- tutorial's been updated, reload it and restart players
    mstore:set_string("tutorial_exile_version", tutorial_version)
end

local counter = 0
repeat
    counter = counter + 1
    local inp = mstore:get("inst_"..tostring(counter))
    if inp and reloading == false then
        instance[counter] = core.deserialize(inp)
        instance[counter].in_use = false
        -- we restarted, nobody's logged in now
    else -- no more instances tracked
        counter = -1
    end
until counter < 0

local function save_out(inst)
    local key = "inst_"..tostring(inst.number)
    local ser = core.serialize(inst)
    mstore:set_string(key, ser)
end


-- Find where the instance goes on the map
local function calc_offset(num)
    -- Offsets by 2k x 2k, leaving ( 0, 9001, 0 ) empty for now
    -- Positive direction only, ~256 tutorial spots seems like plenty
    return vector.new(
        2000 * ( num % 16 ),        -- X
        9281,                       -- Y -- 9280 is a mapchunk boundary
        2000 * math.floor(num / 16) -- Z
    )
end

local function loadschem(anchor, file)
    local filename = modpath.."/schematics/"..file..".ex_schm"
    --minetest.log("action", "Loading schematic: "..filename)
    minimal.load_region(anchor,
                        io.open(filename, "rb"))
end

local function dump_tutorial_state()
    core.log("error", "TUTORIAL INSTANCE READOUT")
    core.log("error", "")
    core.log("error", "Players in: "..dump(i_num))
    core.log("error", "")
    core.log("error", "Instance data: "..dump(instance))
end

local function error_tutorial_state(num)
    core.log("error", "TUTORIAL error: Instance "..
             tostring(num).." does not exist!")
    dump_tutorial_state()
end

local function add_stage(num, finish)
    -- load the next stage, then wait and do it again
    -- finish is the last active stage in an already-setup tutorial area

    if not instance[num] then
        error_tutorial_state(num)
        return
    end

    -- #TODO: Shift this into an interruptible job system
    local inst = instance[num]
    local current = inst.ready + 1
    if stages[current] == nil then return end -- All done
    if finish and current == finish + 1 then
        print("Finished add_stage on ",current, " vs ",finish)
        inst.in_use = false
        inst.active = 0
        return -- Reloaded a previous stage, set inactive
    end
    local anchor = vector.add(inst.offset, stages[current].location)
    loadschem(anchor, stages[current].schem)
    inst.ready = current
    print("add_stage: Stage #",current," is ready")
    save_out(inst)
    minetest.after(delay, add_stage, num, finish)
end

-- Begin reloading any visited stages
local function reload(num)
    if not instance[num] then
        error_tutorial_state(num)
        return
    end
    instance[num].in_use = false
    instance[num].ready = 0
    minetest.after(delay, add_stage, num, instance[num].active)
end

local unload = {}

--[[
    singleplayer: this doesn't run.
                  leaves all as-is. need to record i_num and tables for rejoin
    hosting: doesn't run for first player, treat him like single player
    multi:
]]--
minetest.register_on_leaveplayer(function(player)
        local pname = player:get_player_name()
        if not pname or pname == "" then return end
        local num = i_num[pname]
        if unload[pname] == true then reload(num) end
        i_num[pname] = nil
end)


function stage.shutdown(player) -- For when a player quits the tutorial instance
    local pname = player:get_player_name()
    local num = i_num[pname]
    if not num or minetest.is_singleplayer() then return end
    if instance[num].active == #stages + 1 then -- Finished, clear and reset
        reload(num)
        save_out(instance[num])
    else -- Not complete, keep it set up for the player
        unload[pname] = true
    end
end

-- Spawn the landing zone on first load or when requested if /test_tut is used
local LZ_spawned = mstore:get("tutorial_lz_spawned")
local enable_tutorial = tutorial.enable_tutorial

local function spawn_lz()
            print("TUTORIAL_EXILE: Spawning a Landing Zone")
            loadschem(vector.new(0,9250,0), "landingzone")
            LZ_spawned = true
            mstore:set_string("tutorial_lz_spawned", "true")
end

minetest.after(1, function()
        if ( not LZ_spawned or reloading ) and enable_tutorial then
            print("TUTORIAL_EXILE: Landing Zone RELOAD")
            spawn_lz()
        end
end)

-- Moving players through the stages -------------------------------------

-- Utilities

-- Clears a player's inv and hud and reset attributes, when moving to a stage
local function clear(player)
    local inv = player:get_inventory()
    inv:set_list("main", {})
    inv:set_list("cloths", {})
    player_api.compose_cloth(player)
    player_api.add_player_hand(player)
    HEALTH.show_hud_elements(player, nil, "all")
    HEALTH.reset_attributes(player)
    player:override_day_night_ratio(1)
end

-- Initialize a tutorial instance for this player, or find his existing one
local function stage_init(pname, start_at_stage)
    if not pname or not minetest.get_player_by_name(pname) then
        minetest.log("error",
                     "Tried to init a tutorial instance for non-existant "..
                     " player: ",dump(pname))
        return false
    end
    if i_num[pname] then -- we're already set up?
        return i_num[pname]
    end
    -- Find a spot that isn't taken, spawn an instance there
    local selected = 0
    if not start_at_stage then start_at_stage = 0 end
    local active
    for i = 1, #instance do
        if instance[i].in_use == false
            and instance[i].ready >= start_at_stage then

            selected = i
            instance[i].in_use = true
            active = instance[i].active -- Don't reload past the last used stage
            break
        end
    end
    if selected == 0 then -- didn't find an unused; start anew
        selected = #instance + 1
        instance[selected] = {
            in_use = true, active = 0, ready = 0, number = selected,
            offset = calc_offset(selected)
        }
    end
    i_num[pname] = selected
    save_out(instance[selected])

    minetest.after(2, add_stage, selected, active)
    return selected
end

local function move_to_spawn_pos(player, playername)
    -- Find the current stage's spawn pos and move the player there
    local pname = playername player:get_player_name(player)
    local num = i_num[pname]
    if not num then
        num = stage_init(pname)
    end
    local inst = instance[num]
    local act = inst.active
    local pos = stages[0].start
    if act > 0 then -- We're in the tutorial, respawn at current stage
        pos = ( stages[act].start
                + stages[act].location
                + inst.offset )
    end
    local facing = stages[act].facing
    player:set_look_horizontal(facing)
    player:set_look_vertical(0)

    print("Moving ",pname," to spawn pos for stage ",
          act," at ",core.pos_to_string(pos))
    player:set_pos(pos)
    core.sound_play( {name="lore_gateway", gain=0.20},
        {pos = pos, max_hear_distance=100} )
end


local function enter_stage(player, playername, preferred_stage)
    local pname = playername or player:get_player_name()
    local num = i_num[pname]
    local inst = instance[num]
    if not num or not inst then print("can't enter_stage: ",pname) return end

    if preferred_stage then inst.active = preferred_stage end
    move_to_spawn_pos(player, pname)
    if stages[inst.active].splashtext then
        triggers.hud_splash(player,
                            stages[inst.active].splashicon,
                            stages[inst.active].splashtext,
                            pname)
    end

    if stages[inst.active].entry then
        stages[inst.active]:entry(player, pname, inst)
    end
end

-- called whenever the player moved between stages
local function stage_change(player, playername)
    local pname = playername or player:get_player_name()
    local num = i_num[pname]
    local inst = instance[num]
    if not num or not inst then print("can't stage_change: ",pname) return end

    if stages[inst.active].exit then
        stages[inst.active]:exit(player, playername, inst)
    end

    inst.active = inst.active + 1
    player:get_meta():set_string("tutorial_stage", inst.active)
    clear(player)
    if inst.active > #stages then
        player:get_meta():set_string("tutorial_stage", "")
        tutorial.exit(player)
        return
    end
    save_out(inst)
    enter_stage(player, pname)
end

function stage.open(player) -- called when a player enters the tutorial
    local function stage_go()
        player_api.set_invisible(player, false)
        local pname = player:get_player_name(player)
        local current_stage =
            tonumber(player:get_meta():get("tutorial_stage")) or 0
        if current_stage > #stages then current_stage = 0 end
        local num = i_num[pname]
        if not num then
            stage_init(pname, tonumber(current_stage))
            num = i_num[pname]
        end
        instance[num].active = current_stage
        if current_stage == 0 then -- clear inv on LZ
            clear(player)
        else -- Is player inside the correct tutorial stage already?
            num = i_num[pname]
            local inst = instance[num]
            local start =
                inst.offset + stages[current_stage].location
            local stop = start + stages[current_stage].size
            if player:get_pos():in_area(start, stop) then
                if stage.handlers then
                    for i = 1, #stage.handlers do
                        stage.handlers[i]( stages[current_stage],
                                           player, pname, inst )
                    end
                end
                return -- If so, don't reset
            end
        end

        enter_stage(player, pname, current_stage)
    end

    if not LZ_spawned then
        spawn_lz()
        -- delay for loading LZ, to avoid slowing the subsequent stage loads
        minetest.after(1, stage_go, player)
    else
        stage_go(player)
    end
end

minetest.register_on_respawnplayer(function(player)
        local meta = player:get_meta()
        if meta:get_string("playtime_suspended") == "y" then
            stage.open(player) -- Jump back to the start of the current stage
            return true -- Be sure to disable the core respawn function
        end
end)

-- Trigger ---------------------------------------------------------------

--     local function mytriggerfunc(player, pname, pos, nmeta, metastring) end
--
--     triggers.register("tr_mytrigger", mytriggerfunc, false,
--                       {"My Trigger", "This does custom stuff"})

tutorial = tutorial
triggers = triggers
local used_before = {}

local function stage_trigger(player, pname, pos, nmeta, metastring)
    -- Called when a player reaches the stage exit
    if used_before[pname] then
        return -- prevent player_api calling this again before we're done
    end
    used_before[pname] = true
    stage_change(player, pname)
    used_before[pname] = nil
end

triggers.register("tr_tutnext", stage_trigger, true,
                  {"Stage end", "Place at the exit point of a tutorial stage"})

-- Utilities -------------------------------------------------------------

__DEBUG__ = __DEBUG__
if not __DEBUG__ then return stage end

function stage.distance_to_base(playername)
    local player = core.get_player_by_name(playername)
    local num = i_num[playername]
    local inst = instance[num]
    if not num or not inst then return nil, ("not in a stage") end
    local pos = player:get_pos():round()
    local stagep = stages[inst.active].location
    if inst.active > 0 then stagep = stagep + inst.offset end -- 0 is hardcoded
    return vector.subtract(pos, stagep)
end


minetest.register_chatcommand(
    "tutr_next",{
        privs = "server",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            stage_change(core.get_player_by_name(name), name)
        end
})

minetest.register_chatcommand(
    "tutr_dumpstage",{
        privs = "server",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            dump_tutorial_state()
        end
})

return stage
