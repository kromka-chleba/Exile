--tutorial_exile
--
--If enabled, will be called by lore/login.lua, and ask new players if they
-- would like help learning the game. Clicking yes will generate a tutorial
-- zone above y = 9000, which will walk them through the basics of shelter,
-- fire, food, water, and crafting.

local disable_tutorial = minetest.settings:get("exile_notutorialprompt") or true
-- #TODO: switch this to "or false" when it's debugged and ready to use
-- Set this to true in minetest.conf if the tutorial is completed in singleplayer

tutorial = {}

local pstore = {} -- store status of players so we can restore it after tutorial

local confirmspec = ""

function tutorial.init(player, exitfunc)
   if disable_tutorial then return end
   local name = player:get_player_name()
   pstore[name] = {}
   pstore[name].exit = exitfunc
   minetest.show_formspec(name, confirmspec)
end

local function store_player(player)
   local name = player:get_player_name()
   local ps = pstore[name]
   ps.pos = player:get_pos()
   ps.hp = player:get_hp()
   -- #TODO: get hunger/etc; for people doing the tutorial later optionally
   --  Unnecessary on first login, we'll reset it all when they spawn in anyway
   --  Inventory, too!
end

local function restore_player(player)
   local name = player:get_player_name()
   local ps = pstore[name]
   if not ps then return end
   player:set_pos(ps.pos)
   player:set_hp(ps.hp)
   -- #TODO: Restore stats, inventory
   ps.exit(player) -- call spawn function
end

local function get_valid_tutorial_region(player)
   -- Find a spot that isn't taken, spawn schematic there
   return ( { spawnpos = {x=0,y=9001,z=0},
	      pos1 = vector.new(0,9000,0),
	      pos2 = vector.new(100,9100,100) })
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
      if formname == "tutorial_exile:confirm" then
	 local tut_region = get_valid_tutorial_region(player)
	 store_player(player)
	 player:set_pos(tut_region.spawnpos)
	 player:set_armorgroups({ fleshy = 100, immortal = 1})
      end
end)

function tutorial.exit(player)
   -- Shut down tutorial, delete regions, possibly rewrite starting area
   restore_player(player)
end

--Tutorial nodes
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
	inventory_image = "tech_trapdoor_wattle_side.png",
        groups = {temp_pass = 1},
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
