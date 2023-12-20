--tutorial_exile
--
--If enabled, will be called by lore/login.lua, and ask new players if they
-- would like help learning the game. Clicking yes will generate a tutorial
-- zone above y = 9000, which will walk them through the basics of shelter,
-- fire, food, water, and crafting.

local disable_tutorial = minetest.settings:get("exile_notutorialprompt") or true
-- #TODO: switch this to "or false" when it's debugged and ready to use
-- Set this to true in minetest.conf if the tutorial is completed in singleplayer

local S = minetest.get_translator("tutorial_exile")
tutorial = {}

--------------------------------------------------------------------------------
-- Entry/exit from tutorial

local pstore = {} -- store status of players so we can restore it after tutorial

local welcome = S("Welcome to Exile!")
local intro = S("tut_intro") -- Make translator's job easier
if string.match(intro, "tut_intro") then -- no translation, use default text
   intro =
      "Exile is an original game with unique mechanics\n"..
      "that will be unfamiliar to players of other voxel\n"..
      "games. It may be difficult to learn."
end
local ask = S("tut_ask")
if string.match(ask, "tut_ask") then
   ask =
      "Would you like to take a short tutorial on\n"..
      "how to play the game?"
end

local confirmspec = "formspec_version[6]"..
   "size[8,7]"..
   "hypertext[0.375,0.5;8,5;tut_dialog;"..
   welcome.."\n\n"..intro.."\n\n"..ask.."]"..
   "button_exit[2,6;1,0.5;take_tut;Yes]"..
   "button_exit[5,6;1,0.5;refuse_tut;No]"

function tutorial.init(player, exitfunc)
   if disable_tutorial then
      if exitfunc then exitfunc(player) end
      return
   end
   local name = player:get_player_name()
   pstore[name] = {}
   pstore[name].exit = exitfunc
   minetest.show_formspec(name, "tutorial_exile:confirm", confirmspec)
end

local function store_player(player)
   local name = player:get_player_name()
   local ps = pstore[name]
   ps.pos = player:get_pos()
   ps.hp = player:get_hp()
   local meta = player:get_meta()
   meta:set_string("playtime_suspended", "y")
   -- #TODO: get hunger/etc; for people doing the tutorial later optionally
   --  Unnecessary on first login, we'll reset it all when they spawn in anyway
   --  Inventory, too!
end

local function call_exit(player)
   local name = player:get_player_name()
   local ps = pstore[name]
   if not ps or not ps.exit then return end
   ps.exit(player)
end

local function restore_player(player)
   local name = player:get_player_name()
   local ps = pstore[name]
   if not ps then return end
   player:set_pos(ps.pos)
   player:set_hp(ps.hp)
   local meta = player:get_meta()
   meta:set_string("playtime_suspended", "")
   -- #TODO: Restore stats, inventory
   call_exit(player)
end

local function get_valid_tutorial_region(player)
   -- Find a spot that isn't taken, spawn schematic there
   return ( { spawnpos = {x=0,y=9001,z=0},
	      pos1 = vector.new(0,9000,0),
	      pos2 = vector.new(100,9100,100) })
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
      if formname == "tutorial_exile:confirm" then
	 if not fields.take_tut then -- pressed refuse, or closed the form
	    call_exit(player)
	    pstore[player:get_player_name()] = nil
	    return
	 end
	 local tut_region = get_valid_tutorial_region(player)
	 store_player(player)
	 player:set_pos(tut_region.spawnpos)
	 player:set_armor_groups({ fleshy = 100, immortal = 1})
      end
end)

function tutorial.exit(player)
   -- Shut down tutorial, delete regions, possibly rewrite starting area
   restore_player(player)
end

--------------------------------------------------------------------------------
-- Loading/saving tutorial regions

-- #TODO: move general load/save region functions to utility/vm.lua

minimal = minimal
zone = zone
local vmanip_subregion = minimal.vmanip_subregion
local zone_instance = zone.instance
local worldpath=minetest.get_worldpath()

local function save_region(pos1, pos2, name)
   local cids = { } -- like: { -1 = "unknown", 0 = "ignore", 1 = "air", etc. }
   local dat = {}
   local VoxelManip = minetest.get_voxel_manip()
   local p1, p2 = VoxelManip:read_from_map(pos1, pos2)
   local VoxAr = VoxelArea(p1, p2)
   local nodes = VoxelManip:get_data()
   local param2 = VoxelManip:get_param2_data()
   local tmplist = minetest.find_nodes_with_meta(pos1, pos2)
   local mlist = {}
   for i = 1, #tmplist do -- convert pos values to index values
      mlist[VoxAr:indexp(tmplist[i])] = tmplist[i]
   end

   --local light = vm:get_light_data() -- do we need to store light values?

   local r = vmanip_subregion(pos1, pos2, p1, p2)
   for z = r.zstart, r.zstop, r.zstep do
      for y = r.ystart, r.ystop, r.ystep do
	 for x = r.xstart, r.xstop, r.xstep do
	    local index = x+y+z+1
	    local this = nodes[index]
	    if not cids[this] then
	       cids[this] = minetest.get_name_from_content_id(this)
	    end
	    local met
	    if mlist[index] then
	       local meta = minetest.get_meta(mlist[index])
	       met = meta:to_table()
	       if met.inventory then
		  met.inventory = minimal.invlists2string(met.inventory)
	       end
	    end
	    table.insert(dat, {id = this, p2 = param2[index], meta = met })
	 end
      end
   end
   local out = { "ex_schm_v1.0",
		 { pos1 = pos1, pos2 = pos2 },
		 cids,
		 dat
   }
   local f = io.open(worldpath.."/"..name..".ex_schm","wb")
   f:write(minetest.compress(minetest.serialize(out), "zstd"))
   f:close()
   return "Saved successfully"
end


local function load_region(base_raw, name)
   local f = io.open(worldpath.."/"..name..".ex_schm","rb")
   local read = f:read("*all")
   if not read then return "could not find "..name..".ex_schm"end
   --local input = minetest.deserialize(minetest.decompress(read, "zstd"))
   local inp = minetest.decompress(read, "zstd")
   f:close()
   local input = minetest.deserialize(inp)
   if not input then return "could not load "..name..".ex_schm" end
   local version, range, cids, dat = unpack(input)
   local base = vector.round(base_raw)
   minetest.log("action", ("Found ex_schm version "..
			   version:gsub("ex_schm_","").." and loaded"))
   local xlate = vector.subtract(base, range.pos1) -- for translating pos values
   local pos1 = base
   local pos2 = vector.add(range.pos2, xlate)
   local VoxelManip = minetest.get_voxel_manip()
   local p1, p2 = VoxelManip:read_from_map(pos1, pos2)
   local VoxAr = VoxelArea(p1, p2)
   local r = vmanip_subregion(pos1, pos2, p1, p2)
   local nodes = VoxelManip:get_data()
   local param2 = VoxelManip:get_param2_data()
   local count = 1
   for z = r.zstart, r.zstop, r.zstep do
      for y = r.ystart, r.ystop, r.ystep do
	 for x = r.xstart, r.xstop, r.xstep do
	    local index = x+y+z+1
	    local this = dat[count]
	    nodes[index] = minetest.get_content_id(cids[this.id])
	    param2[index] = this.p2
	    local tpos = VoxAr:position(index)
	    if this.meta then
	       if this.meta.inventory then
		  this.meta.inventory =
		     minimal.string2invlists(this.meta.inventory)
	       end
	       local tmeta = this.meta.fields
	       if tmeta.ztr_id then -- it's a zone, create an instance
		  this.meta.fields = zone_instance(tpos, tmeta)
	       end
	       minetest.get_meta(tpos):from_table(this.meta)
	    end
	    count = count + 1
	 end
      end
   end
   VoxelManip:set_data(nodes)
   VoxelManip:set_param2_data(param2)
   VoxelManip:write_to_map()
   zone_instance() -- close the instancer and fire up all loaded zones
end

--------------------------------------------------------------------------------
-- Tutorial nodes

minetest.register_node("tutorial_exile:invisible_wall", {
        description = "Tutorial boundary wall",
        tiles = {"climate_air.png"},
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
	pointable = false,
        walkable = true,
        buildable_to = false,
        floodable = false,
	wield_image = "tech_trapdoor_wattle_side.png",
	inventory_overlay = "tech_trapdoor_wattle_side.png",
        groups = {temp_pass = 1, not_in_creative_inventory = 1},
	post_effect_color = {a = 5, r = 254, g = 254, b = 254},
	color = {a=0, r=254, g = 254, b = 254},
	use_texture_alpha = "blend",
})

minetest.register_ore({
  ore_type        = "stratum",
  ore             = "tutorial_exile:invisible_wall",
  wherein         = {"air"},
  clust_scarcity  = 1,
  y_max           = 9000,
  y_min           = 9000,
  stratum_thickness = 1,
})

minetest.register_node('tutorial_exile:wall', {
        description = 'Tutorial wall',
        tiles = {
                "tech_rammed_earth.png",
                "tech_rammed_earth_side.png",
        },
	groups = { not_in_creative_inventory = 1 },
})

if minetest.is_creative_enabled() then
   minetest.override_item("tutorial_exile:invisible_wall", {
		drawtype = "glasslike",
		pointable = true,
		diggable = true,
		groups = {crumbly = 1, cracky = 3,
			  temp_pass = 1},
   })
   minetest.override_item('tutorial_exile:wall', {
			     groups = {crumbly = 1, cracky = 3},
   })
end

local lpname = "tut_lighted_path"
local lpdef = {
        description = 'Lighted Path',
        tiles = { {
	   name = lpname,
	   animation = { type = "vertical_frames",
			 aspect_w = 1,
			 aspect_h = 1,
			 length = 3 }
	}},
	groups = { not_in_creative_inventory = 1,
		   oddly_breakable_by_hand = 1},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
	   local name = itemstack:get_name()
	   local pfx = "tutorial_exile:tut_lighted_path"
	   local num = tonumber((name:gsub(pfx,"")))
	   num = num +1 if num == 9 then num = 1 end
	   itemstack:replace(pfx..tostring(num))
	end,
}
if minetest.is_creative_enabled() then lpdef.diggable = true end
for i = 1, 8 do
   local def = table.copy(lpdef)
   local name = lpname..tostring(i)
   def.tiles[1].name = name..".png"
   if i == 1 and minetest.is_creative_enabled() then
      def.groups.not_in_creative_inventory = 0
   end
   minetest.register_node("tutorial_exile:"..name, def)
end



minetest.register_node("tutorial_exile:wet_silt_grass", {
        description = "Wet Woodland Soil",
        tiles = {"nodes_nature_woodland_soil.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^"..
		    "nodes_nature_woodland_soil_side.png^"..
		    "nodes_nature_mud.png"
},
	sounds = { footstep = {name = "nodes_nature_mud", gain = 0.4},
		   dug = {name = "nodes_nature_mud", gain = 0.4} },
	groups = { crumbly = 3, falling_node = 1, puts_out_fire = 1,
		   not_in_creative_inventory = 1 }
})

minetest.register_node("tutorial_exile:wet_silt", {
        description = "Wet Silt",
        tiles = {"nodes_nature_silt.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^nodes_nature_mud.png"
},
	sounds = { footstep = {name = "nodes_nature_dirt_footstep", gain = 0.4},
		   dig = {name = "nodes_nature_dig_crumbly", gain = 1.0},
		   dug = {name = "nodes_nature_dirt_footstep", gain = 1.0}
	},
	groups = { crumbly = 3, falling_node = 1, puts_out_fire = 1,
		   not_in_creative_inventory = 1 }
})

--------------------------------------------------------------------------------
-- Debug commands

minetest.register_chatcommand("test_tut",{
	privs = "server",
	func = function(name,param)
	   local tmp = disable_tutorial
	   disable_tutorial = false
	   minetest.chat_send_player(name, "Starting tutorial")
	   tutorial.init(minetest.get_player_by_name(name), nil)
	   disable_tutorial = tmp
	end
})
minetest.register_chatcommand("quit_tut",{
	privs = "server",
	func = function(name,param)
	   minetest.chat_send_player(name, "Stopping tutorial")
	   tutorial.exit(minetest.get_player_by_name(name))
	end
})
minetest.register_chatcommand("save_tutr",{
	privs = "server",
	func = function(name,param)
	   minetest.chat_send_player(name, "Saving region named "..param)
	   return save_region(vector.new(0,9001,0), vector.new(0,9011,0), param)
	end
})

minetest.register_chatcommand("load_tutr",{
	privs = "server",
	func = function(name,param)
	   minetest.chat_send_player(name, "Loading region named "..param)
	   local player = minetest.get_player_by_name(name)
	   local pos = player:get_pos()
	   return load_region(pos, param)
	end
})
