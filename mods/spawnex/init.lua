--------------------------------------------------------------------------
-- Spawn infrastructure

-- A region's spawn gate is either missing, queued, potential, or open.
-- When a player spawns in, he is sent through a vald open gate first. If
-- there is no open gate already, a potential gate is opened. If there is no
-- potential gate (the missing state) then a gate must be created rapidly
-- via the fast_gate() function.

-- After a gate is opened and player has spawned through it, a new gate
-- location is queued. 60 seconds later, the open gate is closed and the
-- queued gate becomes the region's current potential gate.

-- A potential or queued gate has been set up via finding a spawn position,
-- and emerging the area if possible.


-- Dependencies
__DEBUG__ = __DEBUG__
volcano = volcano
mapchunk_shepherd = mapchunk_shepherd
local ms = mapchunk_shepherd

local function pirnt(...) -- lol print
   local tab = {...}
   local out = ""
   for i = 1, #tab do
      out = out..tostring(tab[i])
   end
   minetest.log("action", out)
end

-- Config options
local wide_spawn = minetest.settings:get_bool("exile_wide_spawn") or true

-- Load hex tools
local modpath = minetest.get_modpath("spawnex")
local dirstring, hexnum,
   hex2string, string2hex,
   hex2map, map2hex,
   get_neighbor, get_neighbors,
   distance_to_hex, hexdir_from_look_horiz = dofile(modpath.."/hex.lua")

local defhex = {0,0}

local function fallback_spawn_pos(hex)
   -- Used if we have to fallback to the hex center for some reason, eg volcano
   pirnt("fallback_spawn_pos")
   local pos = hex2map(hex)
   local vground = volcano.estimate_ground_level(pos)
   local vgl = vground or 20
   local tries = 0
   local sl local xo local zo
   repeat
      tries = tries + 1
      xo = math.random(0,600)-300 zo = math.random(0,600)-300
      sl = minetest.get_spawn_level(pos.x + xo, pos.z + zo)
   until tries == 30 or ( sl and sl > vgl )
   if sl and vgl > sl then
      sl = vgl
   end
   if not sl then -- fallback if all tries failed:
      sl = 20 -- try not to put the player underground
   end
   return vector.new(pos.x + xo, sl, pos.z + zo)
end

local badplaces = {"ocean", "mountains"}
local badbiomes = { "water"}

local function isagoodbiome(name)
   for i = 1, #badbiomes do
      if name:match(badbiomes[i]) then
	 return false
      end
   end
   return true
end

local function spawn_offset(hex1, max_count)
   -- Gets a random spot in a circular field around the center of the region
   local hexctr = hex2map(hex1) -- get the center
   local tgt, d, sl, vgl
   local slcount, biomecount = 0, 0
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
      if not sl then
	 slcount = slcount + 1
	 else
	    vgl = volcano.estimate_ground_level(check) or 0
	    local chunk = ms.mapchunk_hash(check)
	    local bname =
	       minetest.get_biome_name(minetest.get_biome_data(
					  vector.new(check.x,
						     sl or 19,
						     check.z)).biome)
	    if not isagoodbiome(bname) then biomecount = biomecount + 1 end
	    if  sl > vgl and -- not at a volcano
	       not ms.contains_labels(chunk, badplaces)
	       -- not a blacklisted label
	       and  isagoodbiome(bname) then -- not a blacklisted biome name
	       tgt = check
	    end
	 end
      count = count + 1
   until count >= maxcount or tgt
   if tgt then
      tgt.y = sl
   end -- apply spawn level, or return nil
   pirnt("spawn_offset ",hex2string(hex1),
	 (tgt == nil and " NOT" or "    ")," FOUND - ",
	 "tries/sl/biome: ", count,"/",slcount,"/",biomecount)
   return tgt
end

--------------------------------------------------------------------------
-- Region layer

local storage = minetest.get_mod_storage()

region = {}
rgns = minetest.deserialize(storage:get_string("regions")) or {}
-- #TODO: Split region saving up so we don't save them all every time

local jobs = minetest.deserialize(storage:get_string("jobs")) or {}
-- jobs: could have used minetest.after, but we want to save it on restart

--[[
   { ["0:0"] = { [currentgate] = pos, ["nextgate"] = pos,
     ["open"] = true, [..] = ... } }
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

local function find_gate_pos(hex, tries) -- pick a spawn position in a hex
   local gate = spawn_offset(hex, tries or 350)
   if not gate then
      pirnt("bad gate for ",hex2string(hex))
      add_job("setup", 1, hex)
   end
   return gate
end

local function load_gate(hex) -- forceload a gate's location to prep for a spawn
   pirnt("Load gate for ",hex2string(hex))
   local def = region.get(hex)
   pirnt(dump(def))
   if def.forceloaded == true then return end
   local mb_min = vector.new(math.floor(def.currentgate.x / 16) * 16,
			     math.floor(def.currentgate.y / 16) * 16,
			     math.floor(def.currentgate.z / 16) * 16)
   local mb_max = vector.new(mb_min.x + 15, mb_min.y + 15, mb_min.z + 15)
   minetest.emerge_area(mb_min, mb_max)
   minetest.forceload_block(def.currentgate)
   def.forceloaded = true
   save_rgns()
end

local function setup_gate(hex) -- create potential gate
   local def = region.get(hex)
   if not def.currentgate then
      pirnt("setup new gate for ",hex2string(hex))
      def.currentgate = find_gate_pos(hex)
      save_rgns()
      return true
   end
   return false
end

function queue_next_gate(hex) -- Set up next gate before closing current one
   pirnt("queue next gate")
   local def = region.get(hex)
   if def.nextgate then return end -- already have one queued
   local candidate
   local count = 0
   repeat
      candidate = find_gate_pos(hex)
      count = count + 1
   until count > 3 or candidate:distance(def.currentgate) > 400
   -- not too close to previous spawn, please
   def.nextgate = candidate
   save_rgns()
end

function region.fast_gate(hex) -- No gate for this hex, make one quick!
   local gate = find_gate_pos(hex, 25) -- just 25 tries before giving up
   if not gate then
      gate = fallback_spawn_pos(hex)
   end
   local def = region.get(hex)
   def.currentgate = gate
   save_rgns()
   return gate
end

local function close_gate(hex)
   local def = region.get(hex)
   local oldgate = def.currentgate
   if def.forceloaded then minetest.forceload_free_block(oldgate) end
   def.currentgate = def.nextgate
   def.open = false
   def.forceloaded = false
   def.nextgate = nil
   setup_gate(hex)
   save_rgns()
end

local function select_hex_from(hex) -- for wide spawn
   -- Pick a valid hex within a 1-hex range, ensure there's a gate somewhere
   local neigh = get_neighbors(hex)
   table.insert(neigh, hex) -- add the middle in, too
   local open = {} -- A gate is open here, send player here first if possible
   local potentials = {} -- A gate pos has been selected
   local missing = {} -- Nothing is ready here, last resort
   local full_list = {} -- combined potentials and missing for random select
   for i = 1, #neigh do
      if #neigh[i] == 2 then -- this is a valid hex
	 local def = region.get(neigh[i])
	 if def.open then
	    table.insert(open, neigh[i])
	 elseif def.currentgate then
	    table.insert(potentials, neigh[i])
	    table.insert(full_list, neigh[i])
	 else
	    table.insert(missing, neigh[i])
	    table.insert(full_list, neigh[i])
	 end
      end
   end
   pirnt("select hex from ",hex2string(hex)," open: ",#open,
	 " ready: ",#potentials," missing: ",#missing, " full_list: ",#full_list)
   -- Corners can have as few as two neighbors, and if they're open, #missing = 0
   if #missing > 0 then -- pick out a new gate for this area
      local selhex = missing[math.random(1, #missing)]
      pirnt("adding a new gate")
      setup_gate(selhex)
      table.insert(potentials, selhex)
   end
   if #open > 0 then
      pirnt("Selected an opened gate")
      return open[math.random(1, #open)]
   end
   for i = 1, #potentials do -- 2x chance to get potential gate
      table.insert(full_list, potentials[i])
   end
   local newgate = full_list[math.random(1, #full_list)]
   pirnt("Selected gate at ",hex2string(newgate))
   if not region.get(newgate).currentgate then -- we hit a missing gate anyway
      pirnt("And scanning it:")
      setup_gate(newgate)
   end
   return newgate
end

function region.prespawn(player, centrhx) -- Ready a spawn gate for this player
   pirnt("region prespawn")
   local meta = player and player:get_meta()
   if not meta then return end
   local home = centrhx or string2hex(meta:get("exile_spawnhome")) or defhex
   local tgt = home
   if wide_spawn then
      tgt = string2hex(meta:get_string("exile_spawnat")) or select_hex_from(home)
   end
   local rdef = region.get(tgt)
   local gate = rdef.currentgate
   if not gate then setup_gate(tgt) end
   load_gate(tgt)
   meta:set_string("exile_spawnat", hex2string(tgt))
end

local function fixplayer(player)
   if not minetest.is_player(player) then return end
   pirnt("Fixplayer needed for "..player:get_player_name() )
   local pos = player:get_pos()
   local node = minetest.get_node(pos)
   if node.name == "ignore" then
      minetest.after(0.1, fixplayer, player)
      return
   end
   local light = minimal.get_daylight(pos, 0.5)
   if light < 6 then
      player:set_pos(vector.new(pos.x, pos.y + 5, pos.z))
      minetest.after(0.1, fixplayer, player)
      return
   end
   return -- light > 5 indicates we're probably not underground
end

function region.spawn(player)
   pirnt("region spawn")
   local meta = player:get_meta()
   local home = string2hex(meta:get("exile_spawnhome")) or defhex
   local spawnat = home
   if wide_spawn then
      spawnat = string2hex(meta:get("exile_spawnat")) or select_hex_from(home)
      meta:set_string("exile_spawnat", "") -- clear the used spawn pos
   end

   local sadef = region.get(spawnat)
   local gate = sadef.currentgate
   local guessed_gate = false
   if not gate then
      gate = region.fast_gate(spawnat)
      sadef.currentgate = gate
      load_gate(spawnat)
      guessed_gate = true
   end
   sadef.open = true
   pirnt("spawn: ",dump(sadef.currentgate))
   player:set_pos(gate)
   if guessed_gate then fixplayer(player) end
   -- get a new spawn location, but wait until this gate is closed!
   minetest.after(70, function() region.prespawn(player) end )
   add_job("queue", 20, spawnat)
   add_job("close", 60, spawnat)
   save_jobs()
end

--------------------------------------------------------------------------
-- Player tracking and update jobs

local timer = 0

local homecache = {}
local savejobs = false

local func = -- can't serialize actual functions, so correlate with string name
   { ["queue"] = queue_next_gate, ["close"] = close_gate,
      ["setup"] = setup_gate, }

-- how far you need to get from center of home to new home
local maxdist = 2750 -- 2000 to the edge of the next hex, 1250 from its center
local maxdist_wide = maxdist + 4000 -- one extra hex out, drags center behind
local shift = {} -- stores midway region, in wide spawn. for this ^^

local function player_moved_to_new_region(player, pname, ppos, home)
   -- If a player moves far enough from his home region, we need to set
   --  the new region as his home, for regular spawn. Wide spawn will
   --  drag a "shift" hex out from home, and then set it when the player
   --  is far enough from the shift hex.
   local saveout = false
   local newhex = map2hex(ppos)
   local disthome = distance_to_hex(ppos, home)
   if  disthome > maxdist then
      if not wide_spawn then
	 homecache[pname] = newhex
	 saveout = true
      elseif not shift[player] then
	 shift[player] = newhex -- this is important if player teleported
      else -- wide spawn, and we have a shift region already; what do?
	 if disthome > maxdist_wide then -- far out, move the player's home
	    pirnt(pname..": updated home to: ",hex2string(shift[player]))
	    homecache[pname] = shift[player]
	    shift[player] = nil
	    saveout = true
	 elseif disthome < maxdist then -- came back home, so remove shift
	    shift[player] = nil
	 elseif ( disthome < maxdist / 2 and -- circled around, so change shift
		  distance_to_hex(shift[player]) > maxdist ) then
	    shift[player] = newhex
	 end
      end
   end
   return saveout
end

minetest.register_globalstep(function(dtime)
      for nm, dat in pairs(jobs) do -- run jobs
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
	 timer = 0 -- Check for players who have moved
	 for _, player in pairs(minetest.get_connected_players()) do
	    local pname = player:get_player_name()
	    local home = homecache[pname]
	    local meta -- only read it if we need it, and hold it for later
	    local saveout = false
	    if not home then
	       meta = player:get_meta()
	       home = string2hex(meta:get_string("exile_spawnhome"))
	       if not home then
		  home = defhex -- default for new players
		  saveout = true
	       end
	       homecache[pname] = home
	    end
	    local ppos = player:get_pos()
	    local dfrom = distance_to_hex(ppos, home)
	    if dfrom > maxdist then -- we're well out of our home region
	       saveout = saveout or player_moved_to_new_region(player, pname,
							       ppos, home)
	       home = homecache[pname] -- in case we updated
	    end
	    if saveout then
	       if not meta then meta = player:get_meta() end
	       meta:set_string("exile_spawnhome", hex2string(home))
	       meta:set_string("exile_spawnat", "")
	       pirnt(pname..": home hex changed, selecting spawn pos")
	       region.prespawn(player, home)
	    end
	 end
      end
end)

--------------------------------------------------------------------------
-- Startup and new player setup

minetest.register_on_mods_loaded(function()
      minetest.after(0.1, function()
	if wide_spawn then -- Check area, ensure there's a gate set up
	   pirnt("Wide spawn enabled, checking default spawn area for gates")
	   select_hex_from(defhex)
	   return
	end
	-- not wide_spawn? check defhex only, set up a gate if needed
	if not rgns[hex2string(defhex)] then
	   setup_gate(defhex)
	end
      end)
end)

minetest.register_on_joinplayer(function(player)
      local pname = player:get_player_name()
      local meta = player:get_meta()
      local home = string2hex(meta:get_string("exile_spawnhome"))
      if not home then
	 pirnt("Player "..pname.." joined without a home region")
	 home = defhex
	 meta:set_string("exile_spawnhome", hex2string(home))
      end -- default for new players
      homecache[pname] = home
end)

minetest.register_on_dieplayer(function(player)
      pirnt("Player "..player:get_player_name()..
	    " died, calling region.prespawn")
      region.prespawn(player)
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
	   local spos = spawn_offset(tgt)
	   if spos == nil then return false, "can't find a valid pos" end
	   minetest.get_player_by_name(name):set_pos(spos)
	   return true, minetest.pos_to_string(ppos).." -> "..
	      minetest.pos_to_string(spos)
	end
})

minetest.register_chatcommand("spawnlevel",{
	--privs = "server",
	func = function(name,param)
	   pirnt("Checking SL")
	   local player = minetest.get_player_by_name(name)
	   local ppos = player:get_pos()
	   local sl = minetest.get_spawn_level(ppos.x, ppos.z)
	   pirnt("SPAWN LEVEL: ",sl)
	   pirnt("VOLCANO LEVEL: ",volcano.estimate_ground_level(ppos))
	   return true, sl
	end
})

minetest.register_chatcommand("biome",{
	--privs = "server",
	func = function(name,param)
	   local player = minetest.get_player_by_name(name)
	   local ppos = player:get_pos()
	   local dat = minetest.get_biome_data(ppos)
	   return true, minetest.get_biome_name(dat.biome)
	end
})
minetest.register_chatcommand("hexstat",{
	--privs = "server",
	func = function(name,param)
	   local player = minetest.get_player_by_name(name)
	   local ppos = player:get_pos()
	   local hex = string2hex(param) or map2hex(ppos)
	   local r = region.get(hex)
	   if not r.currentgate then return true, "unloaded" end
	   return true, "Hex at "..hex2string(hex).." : \n"..
	      (r.currentgate and "Current gate: "..
	       minetest.pos_to_string(r.currentgate) or "No current gate")..
	      (r.forceloaded and "[Loaded]" or "")..
	      (r.open and "[Open]" or "")..
	      (r.nextgate and "\nNext gate: "..
	       minetest.pos_to_string(r.currentgate) or "")
	end
})

minetest.register_chatcommand("myhex",{
	--privs = "server",
	func = function(name,param)
	   local player = minetest.get_player_by_name(name)
	   local meta = player:get_meta()
	   return true, "Your hex home is :"..
	      meta:get_string("exile_spawnhome")..
	      " Wide spawn is "..(wide_spawn and "enabled"..
				  " and you will spawn in "..
				  (meta:get("exile_spawnat") or "??")
				  or "disabled")
	end
})

minetest.register_chatcommand("newgate",{
	--privs = "server",
	func = function(name,param)
	   local hex = string2hex(param)
	   if not hex then
	      return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
	   end
	   close_gate(hex)
	   setup_gate(hex)
	   local out =  "Set up new gate for "..hex2string(hex).." at "
	   local pos = region.get(hex).currentgate
	   out = out .. minetest.pos_to_string(pos)
	   return true, out
	end
})

minetest.register_chatcommand("fbspawn",{
	--privs = "server",
	func = function(name,param)
	   local tgt = string2hex(param)
	   if not tgt then
	      return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
	   end
	   local player = minetest.get_player_by_name(name)
	   local ppos = player:get_pos():round()
	   local spos = fallback_spawn_pos(tgt)
	   if spos == nil then return false, "can't find a valid pos" end
	   player:set_pos(spos)
	   return true, minetest.pos_to_string(ppos).." -> "..
	      minetest.pos_to_string(spos)
	end
})

minetest.register_chatcommand("fixplayer",{
	--privs = "server",
	func = function(name,param)
	   local player
	   if param then
	      player = minetest.get_player_by_name(param)
	   end
	   if not player then
	      player = minetest.get_player_by_name(name)
	   end
	   fixplayer(player)
	end
})

end

