--tutorial
--
--If enabled, will be called by lore/login.lua, and ask new players if they
-- would like help learning the game. Clicking yes will generate a tutorial
-- zone above y = 9000, which will walk them through the basics of shelter,
-- fire, food, water, and crafting.

--Tutorial nodes
minetest.register_node("tutorial:invisible_wall", {
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
  ore             = "tutorial:invisible_wall",
  wherein         = {"air"},
  clust_scarcity  = 1,
  y_max           = 9000,
  y_min           = 9000,
  stratum_thickness = 1,
})

minetest.register_node('tutorial:wall', {
        description = 'Tutorial wall',
        tiles = {
                "tech_rammed_earth.png",
                "tech_rammed_earth_side.png",
        },
})

if minetest.is_creative_enabled() then
   minetest.override_item("tutorial:invisible_wall", {
		drawtype = "glasslike",
		pointable = true,
		diggable = true,
		groups = {crumbly = 1, cracky = 3,
			  temp_pass = 1},
   })
   minetest.override_item('tutorial:wall', {
			     groups = {crumbly = 1, cracky = 3},
   })
end
