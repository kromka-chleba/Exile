-- stage.lua -------------------------------------------------------------

-- Tracks the player's progress through the stages of the tutorial
--  Allows players to die and go back to the start of a stage, or exit/enter

local stage = {} -- namespace

local modpath = minetest.get_modpath("tutorial_exile")
local stages = dofile(modpath..'/data_stages.lua')

-- Loading/unloading areas -----------------------------------------------

local delay = 11 -- number of seconds to wait before loading next stage
local i_num = {} -- [playername ] = [tutorial_instance_number]
local instance = {} -- track instance contents, to repurpose them. contains:
--[[a= {
    [instance_num] = {
    in_use = false,
    active = 0, -- last active stage #
    ready = 0, -- counts up when a stage has finished loading
    offset = vector.new(), -- cached offset
    }
    }]]--


-- Find where the instance goes on the map
local function calc_offset(num)
    -- Offsets by 2k x 2k, leaving ( 0, 9001, 0 ) empty for now
    -- Positive direction only, ~30 tutorial spots seems like plenty for now
    return vector.new(
        2000 * ( num % 16 ),        -- X
        9251,                       -- Y
        2000 * math.floor(num / 16) -- Z
    )
end

local function loadschem(anchor, file)
    local filename = modpath.."/schematics/"..file..".ex_schm"
    minetest.log("action", "Loading schematic: "..filename)
    minimal.load_region(anchor,
                        io.open(filename, "rb"))
end

local function add_stage(num, finish)
    -- load the next stage, then wait and do it again
    -- finish is the last active stage in an already-setup tutorial area

    -- #TODO: Shift this into an interruptible job system
    print("Add stage ",num," / ",finish)
    local inst = instance[num]
    local current = inst.ready + 1
    if stages[current] == nil then return end -- All done
    if finish and current == finish + 1 then
        inst.in_use = false return -- Reloaded a previous stage, set inactive
    end
    local anchor = vector.add(inst.offset, stages[current].location)
    loadschem(anchor, stages[current].schem)
    inst.ready = current
    minetest.after(delay, add_stage, num, finish)
end

local function reload(num)
    -- reload any visited stages
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
    unload[pname] = true
end

-- Spawn the landing zone on first load, set a map_meta env to track
local LZ_spawned = minetest.get_mapgen_setting("tutorial_lz_spawned")
if not LZ_spawned then core.set_mapgen_setting("tutorial_lz_spawned", "true") end
local enable_tutorial = minetest.settings:get("exile_enabletutorial") or true
minetest.after(1, function()
        print("-------LZ------ ",not LZ_spawned, enable_tutorial)
        if (not LZ_spawned) and enable_tutorial then
            print("Tutorial: Spawning Landing Zone")
            loadschem(vector.new(0,9250,0), "landingzone")
        end
        print("-------LZ------ ")
end)

-- Moving players through the stages -------------------------------------

-- Initialize a tutorial instance for this player, or find his existing one
local function stage_init(pname, selected_stage)
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
    local active
    for i = 1, #instance do
        if not instance[i].in_use then
            selected = i
            instance[i].in_use = true
            active = instance[i].active + 1
        end
    end
    if selected == 0 then -- didn't find an unused; create new
        selected = #instance + 1
        instance[selected] = {
            in_use = true, active = 0, ready = 0,
            offset = calc_offset(selected)
        }
    end
    i_num[pname] = selected

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

    -- not currently in, send him to the landing zone
    print("Moving to spawn pos for stage ",act," at ",core.pos_to_string(pos))
    player:set_pos(pos)
end


local function enter_stage(player, playername)
    local pname = playername or player:get_player_name()
    local num = i_num[pname]
    local inst = instance[num]
    if not num or not inst then print("can't enter_stage: ",pname) return end

    move_to_spawn_pos(player, pname)
    print("Entering stage: ",inst.active)
    if stages[inst.active].entry then
        stages[inst.active]:entry(player, pname)
    end
end

-- called whenever the player moved between stages
local function stage_change(player, playername)
    local pname = playername or player:get_player_name()
    local num = i_num[pname]
    local inst = instance[num]
    if not num or not inst then print("can't stage_change: ",pname) return end
    print("Leaving stage ",inst.active," of ",#stages)
    if stages[inst.active].exit then
        stages[inst.active]:exit(player, playername)
    end
    inst.active = inst.active + 1
    if inst.active > #stages then
        print("All done, last stage")
        tutorial.exit(player)
    end
    enter_stage(player, pname)
end

function stage.open(player) -- called when a player enters the tutorial
    local pname = player:get_player_name(player)
    if not i_num[pname] then
        stage_init(pname)
    end
    enter_stage(player)
end


-- Trigger ---------------------------------------------------------------

--     local function mytriggerfunc(player, pname, pos, nmeta, metastring) end
--
--     triggers.register("tr_mytrigger", mytriggerfunc, false,
--                       {"My Trigger", "This does custom stuff"})

tutorial = tutorial
triggers = triggers
local function stage_trigger(player, pname, pos, nmeta, metastring)
    -- Called when a player reaches the stage exit
    stage_change(player, pname)
end

triggers.register("tr_tutnext", stage_trigger, true,
                  {"Stage end", "Place at the exit point of a tutorial stage"})

-- Utilities -------------------------------------------------------------
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


return stage

