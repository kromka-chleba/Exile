-- stage.lua -------------------------------------------------------------

-- Tracks the player's progress through the stages of the tutorial
--  Allows players to die and go back to the start of a stage, or exit/enter

local stage = {} -- namespace

local modpath = minetest.get_modpath("tutorial_exile")
local stages = dofile(modpath..'/data_stages.lua')

--[[ -- no

pi[name] = {
   offset, -- base pos added to the tutorial regions to relocate them
   pos1, pos2, -- map segment reserved for this player
   current = 1, -- which stage he is on, if any
   start = { -- Do we need this? offset and stage data should suffice
      [1] = nil , -- spawnpos for first stage
      [2] = nil , -- second, etc
      },
}

]]--


local function get_playername(player_or_name)
   if type(player_or_name) == "string" then
      return  player_or_name
   else
      return player_or_name:get_player_name()
   end
end

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


local function calc_offset(num)
   -- Offsets by 2k x 2k, leaving ( 0, 9001, 0 ) empty for now
   -- Positive direction only, ~30 tutorial spots seems like plenty for now
   return vector.new(
      2000 * ( num % 16 ),        -- X
      9001,                       -- Y
      2000 * math.floor(num / 16) -- Z
   )
end

local function add_stage(num, finish)
   -- load the next stage, then wait and do it again
   -- finish is the last active stage in an already-setup tutorial area

   -- #TODO: Shift this into an interruptible job system
   local inst = instance[num]
   local current = inst.ready + 1
   if stages[current] == nil then return end -- All done
   if finish and current == finish + 1 then
      inst.in_use = false return -- Reloaded a previous stage, set inactive
   end
   local anchor = vector.add(inst.offset, stages[current].location)
   local filename = modpath.."/schematics/"..stages[current].schem..".ex_schm"
   minetest.log("action", "Loading schematic: "..filename)
   minimal.load_region(anchor,
		       --filename)
		       io.open(filename, "rb"))
   inst.ready = current
   minetest.after(11, add_stage, num, finish)
end

function stage.init(pname, selected_stage)
   if not pname or not minetest.get_player_by_name(pname) then
      minetest.log("error", "Tried to init a tutorial stage for non-existant "..
		   " player: ",dump(pname))
      return false
   end
   if i_num[pname] then -- we're already set up?
      return
   end
   -- Find a spot that isn't taken, spawn an instance there
   local select = 0
   local active
   for i = 1, #instance do
      if not instance[i].in_use then
	 select = i
	 instance[i].in_use = true
	 active = instance[i].active + 1
      end
   end
   if select == 0 then -- didn't find an unused; create new
      select = #instance + 1
      instance[select] = {
	 in_use = true, active = 0, ready = 0,
	 offset = calc_offset(select)
      }
   end
   i_num[pname] = select

   minetest.after(2, add_stage, select, active)
   return select
end

function stage.get_spawn_pos(player_or_name)
   local pname = get_playername(player_or_name)
   local num = i_num[pname]
   if not num then
      num = stage.init(pname)
   end
   if num > 0 then -- We're in the tutorial, respawn at current stage
      local inst = instance[num]
      return stages[num].start + stages[num].location + inst.offset
   end

   return stages["lz"].start -- not currently in, send him to the landing zone
end

-- #TODO: Spawn the landing zone on first load, set a map_meta env to track

local function reload(num)
    -- reload any visited stages
   instance[num].in_use = false
   instance[num].ready = 0
   minetest.after(11, add_stage, num, instance[num].active)
end

local unload = {}

function stage.exit(player) -- For when a player exits the tutorial instance
   local pname = player:get_player_name()
   local num = i_num[pname]
   if not num or minetest.is_singleplayer() then return end
   unload[pname] = true
end

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

-- Trigger ---------------------------------------------------------------

--     local function mytriggerfunc(player, pname, pos, nmeta, metastring) end
--
--     triggers.register("tr_mytrigger", mytriggerfunc, false,
--                       {"My Trigger", "This does custom stuff"})

tutorial = tutorial
triggers = triggers
local function stage_trigger(player, pname, pos, nmeta, metastring)
   -- Called when a player reaches the stage exit
   local num = i_num[pname] -- which instance he's in
   local inst = instance[num]
   if not num or not inst then return end
   if inst.active == #stages then tutorial.exit(player) return end
   print("Leaving stage ",inst.active," of ",#stages)
   inst.active = inst.active + 1
   print("Entering stage ",inst.active," at ",
	 minetest.pos_to_string(stages[num].start + stages[num].location
				+ inst.offset))
   player:set_pos(stages[num].start + stages[num].location + inst.offset)
end

triggers.register("tr_tutnext", stage_trigger, true,
		  {"Stage end", "Place at the exit point of a tutorial stage"})
return stage
