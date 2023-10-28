--------------------------------------------------------------------------
-- Spawn infrastructure

-- dependencies
__DEBUG__ = __DEBUG__
volcano = volcano
mapchunk_shepherd = mapchunk_shepherd
local ms = mapchunk_shepherd

local modpath = minetest.get_modpath("spawnex")
local dirstring, hexnum, -- Load hex tools
   hex2string, string2hex,
   hex2map, map2hex,
   get_neighbor, get_neighbors,
   distance_to_hex, hexdir_from_look_horiz = dofile(modpath.."/hex.lua")

local defhex = {0,0}

local function find_spawn_pos(pos)
   -- Used if we have to fallback to the hex center for some reason, eg volcano
   local vgl = volcano.estimate_ground_level(pos) or 0
   if vgl > 400 then return end -- don't even bother, or we'll end in a caldera
   local tries = 0
   local sl local xo local zo
   repeat
      tries = tries + 1
      xo = math.random(0,600)-300 zo = math.random(0,600)-300
      sl = minetest.get_spawn_level(pos.x + xo, pos.z + zo)
   until tries == 30 or ( sl and sl > vgl )
   if vgl > sl then sl = vgl end -- fallback if all tries failed
   if sl then return vector.new(pos.x + xo, sl, pos.z + zo) end
end

local badplaces = {"ocean", "mountains"}

local function spawn_offset(hex1, max_count)
   -- Gets a random spot in a circular field around the region
   local hexctr = hex2map(hex1) -- get the center
   local tgt, d, sl, vgl
   local count = 0 local maxcount = max_count or 20
   local axis = vector.new(0,1,0)
   repeat
      d = math.random(250,1500)
      local dist = vector.new(d,0,0)
      local maxradians = math.pi * 2
      local angle = math.random(0, maxradians*1000) / 1000 -- 0 to 6.2831 r
      local check = vector.round(hexctr:add(
				    vector.rotate_around_axis(dist,axis,angle)))
      sl = minetest.get_spawn_level(check.x, check.z)
      vgl = volcano.estimate_ground_level(check) or 0
      local chunk = ms.mapchunk_hash(check)
      if (sl and sl > vgl) and not ms.contains_labels(chunk, badplaces) then
	 tgt = check
      end
      count = count + 1
   until count > maxcount or tgt
   if tgt then
      tgt.y = sl
   end -- apply spawn level, or return nil
   return tgt
end

--------------------------------------------------------------------------
-- Region layer

local storage = minetest.get_mod_storage()

region = {}
rgns = minetest.deserialize(storage:get_string("regions")) or {}

local jobs = minetest.deserialize(storage:get_string("jobs")) or {}
-- jobs: could have used minetest.after, but we want to save it on restart

--[[
   { ["0:0"] = { [currentgate] = pos, [nextgate] = pos, [..] = ... } }
]]--

local function save_rgns()
   storage:set_string("regions", minetest.serialize(rgns))
end
local function save_jobs()
   storage:set_string("jobs", minetest.serialize(jobs))
end

function add_job(name, time, hex)
   jobs[name.."_"..hex2string(hex)] = {
      name = name, timer = 0, finish = time, target = hex }
end

function region.get(hex) -- #TODO: add other features for regions
   local id = hex2string(hex)
   if not rgns[id] then
      rgns[id] = {}
   end
   return rgns[id]
end

local function has_gate(hex)
   local def = region.get(hex)
   if def.currentgate then
      return true
   end
end

local function find_gate(hex, tries)
   local gate = spawn_offset(hex, tries or 40)
   if not gate then
      gate = find_spawn_pos(hex2map(hex))
   end
   return gate
end

local function setup_gate(hex)
   local def = region.get(hex)
   if not def.currentgate then
      def.currentgate = find_gate(hex)
   end
   local mb_min = vector.new(math.floor(def.currentgate.x / 16) * 16,
			     math.floor(def.currentgate.y / 16) * 16,
			     math.floor(def.currentgate.z / 16) * 16)
   local mb_max = vector.new(mb_min.x + 15, mb_min.y + 15, mb_min.z + 15)
   minetest.emerge_area(mb_min, mb_max)
   minetest.forceload_block(def.currentgate)
   save_rgns()
end

function queue_gate(hex)
   -- Set up the next gate in preparation for closing the current one
   local def = region.get(hex)
   if def.nextgate then return end -- already have one queued
   local candidate
   local count = 0
   repeat
      candidate = find_gate(hex)
      count = count + 1
   until count > 3 or candidate:distance(def.currentgate) < 400
   -- not too close to previous spawn, please
   def.nextgate = candidate
   save_rgns()
end

function region.fast_gate(hex)
   -- Couldn't find a gate for this hex, make one quick!
   local def = region.get(hex)
   local gate = find_gate(hex, 5) -- just 5 tries before giving up
   def.currentgate = gate
   save_rgns()
   return gate
end

local function close_gate(hex)
   local def = region.get(hex)
   local oldgate = def.currentgate
   minetest.forceload_free_block(oldgate)
   def.currentgate = def.nextgate
   def.nextgate = nil
   setup_gate(hex)
   save_rgns()
end

function region.spawn(player)
   local meta = player:get_meta()
   local home = string2hex(meta:get("exile_spawnat")) or defhex
   local rdef = region.get(home)
   --if hard_spawn then
   --   rdef = region.get(get_neighbors(home)[math.random(1,6)] or home) end
   local gate = rdef.currentgate
   if not gate then
      gate = region.fast_gate(home)
   end
   player:set_pos(gate)
   add_job("queue", 50, home)
   add_job("close", 60, home)
   save_jobs()
end

local timer = 0

local homecache = {}
local savejobs = false

local func = -- can't serialize actual functions, so correlate with string name
   { ["queue"] = queue_gate, ["close"] = close_gate }

minetest.register_globalstep(function(dtime)
      for nm, dat in pairs(jobs) do
	 dat.timer = dat.timer + dtime
	 if dat.timer > dat.finish then
	    func[dat.name](dat.target)
	    jobs[nm] = nil
	    savejobs = true
	 end
      end
      if savejobs == true then save_jobs() savejobs = false end

      timer = timer + dtime
      if timer > 27 then
	 timer = 0
	 for _, player in pairs(minetest.get_connected_players()) do
	    local pname = player:get_player_name()
	    local home = homecache[pname]
	    local meta -- only read it if we need it, and hold it for later
	    local saveout = false
	    if not home then
	       meta = player:get_meta()
	       home = string2hex(meta:get_string("exile_spawnat"))
	       if not home then home = defhex end -- default for new players
	       homecache[pname] = home
	       saveout = true
	    end
	    local ppos = player:get_pos()
	    local dfrom = distance_to_hex(ppos, home)
	    if dfrom > 2750 then -- we're well out of our home region
	       local newhex = map2hex(ppos)
	       if distance_to_hex(ppos, newhex) < 1250 then
		  if not meta then meta = player:get_meta() end
		  home = newhex
		  homecache[newhex] = newhex
		  saveout = true
	       end
	       if not has_gate(newhex) then
		  setup_gate(newhex)
	       end
	       if saveout then
		  if not meta then meta = player:get_meta() end
		  meta:set_string("exile_spawnat", hex2string(home))
	       end
	    end
	 end
      end
end)

--------------------------------------------------------------------------

minetest.register_on_mods_loaded(function()
      minetest.after(0.1, function()
	if not rgns[hex2string(defhex)] then
	   setup_gate(defhex) -- set up a spawn for starting region
	end
      end)
end)

minetest.register_on_joinplayer(function(player)
      local pname = player:get_player_name()
      local meta = player:get_meta()
      local home = string2hex(meta:get_string("exile_spawnat"))
      if not home then
	 home = defhex
	 meta:set_string("exile_spawnat", hex2string(home))
      end -- default for new players
      homecache[pname] = home
      if not has_gate(home) then
	 setup_gate(home)
      end
end)


--------------------------------------------------------------------------
-- Debug commands

if __DEBUG__ then

minetest.register_chatcommand("d2hex",{
	--privs = "server",
	func = function(name,param)
	   local hex = string2hex(param)
	   if not hex then
	      return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
	   end
	   local ppos = minetest.get_player_by_name(name):get_pos():round()
	   local hexpos = hex2map(hex)
	   local dist = vector.distance(ppos, hexpos)
	   return true, "Distance: "..tostring(dist)
	end
})

minetest.register_chatcommand("checkhex",{
	--privs = "server",
	func = function(name,param)
	   local ppos = minetest.get_player_by_name(name):get_pos():round()
	   local nearest = map2hex(ppos)
	   local num = hexnum(nearest)
	   return true, "hex #"..tostring(num).." "..hex2string(nearest)..
	      " center is "..tostring(distance_to_hex(ppos, nearest))..
	      " nodes away."
	end
})

minetest.register_chatcommand("hexneighbors",{
	--privs = "server",
	func = function(name,param)
	   local ppos = minetest.get_player_by_name(name):get_pos():round()
	   local nearest = map2hex(ppos)
	   local wontyoube = get_neighbors(nearest)
	   local num = hexnum(nearest)
	   minetest.chat_send_player(name, "You are in hex #"..tostring(num)
				     ..": "..hex2string(nearest))
	   local liststring = "Neighbors: "
	   for dir, hex in pairs(wontyoube) do
	      liststring = liststring.."\n "..dirstring[dir][2]..": "..
		 hex2string(hex).." -- "..
		 tostring(distance_to_hex(ppos, hex))
	   end
	   return true, liststring
	end
})

minetest.register_chatcommand("hexlook",{
	--privs = "server",
	func = function(name,param)
	   local player = minetest.get_player_by_name(name)
	   local look = player:get_look_horizontal()
	   local ppos = player:get_pos()
	   local dir = hexdir_from_look_horiz(look)
	   local phex = map2hex(ppos)
	   local hex = get_neighbor(phex, dir)
	   return true, "You are facing "..dirstring[dir][1]..", towards hex "..
	      hex2string(hex)
	end
})

minetest.register_chatcommand("hexport",{
	--privs = "server",
	func = function(name,param)
	   local tgt = string2hex(param)
	   if not tgt then
	      return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
	   end
	   local ppos = minetest.get_player_by_name(name):get_pos():round()
	   local hexpos = hex2map(tgt, ppos.y)
	   local spos = spawn_offset(tgt)
	   if spos == nil then return false, "can't find a valid pos" end
	   minetest.get_player_by_name(name):set_pos(spos)
	   return true, minetest.pos_to_string(hexpos).." -> "..
	      minetest.pos_to_string(spos)
	end
})

minetest.register_chatcommand("spawnlevel",{
	--privs = "server",
	func = function(name,param)
	   local player = minetest.get_player_by_name(name)
	   local ppos = player:get_pos()
	   local sl = minetest.get_spawn_level(ppos.x, ppos.z)
	   return true, sl
	end
})

end
