----------------------------------------------------------
--Grafitti
--uses api for registering various painted images
--various symbols and patterns, enough to make it possible to form a symbolic vocabulary.

--colours:
--lime white
--glow paint (a light)
--carbon black --!!
--red ochre --!!

--frequently used symbols could be repeated in each colour
-- plus some unique ones per color for variety
-- few enough that menu is small

----------------------------------------------------------

-- Internationalization
local S = tech.S

grafitti = grafitti

--lime White

local wgraffiti = {

   --abstract
   "lw_x",
   "lw_hourglass1",
   "lw_hourglass2",
   "lw_hourglass3",
   "lw_xox",

   "lw_o",
   "lw_odot",

   "lw_quad",
   "lw_quaddot",

   "lw_oval",
   "lw_ovalfull",

   "lw_square",
   "lw_squarefull",

   "lw_lineh",
   "lw_linev",
   "lw_flute",

   "lw_arrowd",
   "lw_arrowu",
   "lw_arrowl",
   "lw_arrowr",

   "lw_penni1",
   "lw_penni2",
   "lw_pecti1",
   "lw_pecti2",
   "lw_tecti",
   "lw_4pole",
   "lw_avi",
   "lw_scali",
   "lw_bridge",

   "lw_antiq",

   "lw_burst1",
   "lw_burst2",
   "lw_bolt",

   --less abstract
   "lw_hand",
   "lw_hand2",
   "lw_foot",
   "lw_fig1",
   "lw_fig2",
   "lw_fig3",
   "lw_angryface",
   "lw_sadface",
   "lw_surpriseface",
   "lw_fearface",
   "lw_chrysalis"
}

for i, name in ipairs(wgraffiti) do
   grafitti.register_grafitti("tech:"..name,
			      { image = "tech_paint_"..name..".png"})
end

grafitti.palette_build("tech:lime_white")

grafitti.register_brush("tech:paint_lime_white", {
    description = S("Painting Kit (lime white)"),
    inventory_image = "tech_paint_brush_white.png",
    wield_image = "tech_paint_brush_white.png^[transformR270",
    palette = "tech:lime_white"
})


crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:paint_lime_white",
	items = {'tech:crushed_lime', 'tech:stick', 'group:fibrous_plant 4', 'tech:vegetable_oil 4'},
	level = 1,
	always_known = true,
})



----------------------------------------------------------
--glow paint (glowing blue)

grafitti.register_grafitti("tech:gp_dot", {image = "tech_paint_gp_dot.png", light = 2})
grafitti.register_grafitti("tech:gp_x", {image = "tech_paint_gp_x.png", light = 2})
grafitti.register_grafitti("tech:gp_arrowl", {image = "tech_paint_gp_arrowl.png", light = 2})
grafitti.register_grafitti("tech:gp_arrowr", {image = "tech_paint_gp_arrowr.png", light = 2})
grafitti.register_grafitti("tech:gp_arrowd", {image = "tech_paint_gp_arrowd.png", light = 2})
grafitti.register_grafitti("tech:gp_arrowu", {image = "tech_paint_gp_arrowu.png", light = 2})
grafitti.register_grafitti("tech:gp_spsq", {image = "tech_paint_gp_spsq.png", light = 2})
grafitti.register_grafitti("tech:gp_sq", {image = "tech_paint_gp_sq.png", light = 2})

grafitti.palette_build("tech:glow_paint")

grafitti.register_brush("tech:paint_glow_paint", {
    description = S("Painting Kit (glow paint)"),
    inventory_image = "tech_paint_brush_glow.png",
    wield_image = "tech_paint_brush_glow.png^[transformR270",
    palette = "tech:glow_paint"
})


crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:paint_glow_paint",
	items = {'group:bioluminescent 16', 'tech:stick', 'group:fibrous_plant 4', 'tech:vegetable_oil 4'},
	level = 1,
	always_known = true,
})


----------------------------------------------------------
--simple scratcher

grafitti.register_grafitti("tech:scr_1", {image = "tech_paint_scr_1.png"})
grafitti.register_grafitti("tech:scr_2", {image = "tech_paint_scr_2.png"})
grafitti.register_grafitti("tech:scr_3", {image = "tech_paint_scr_3.png"})
grafitti.register_grafitti("tech:scr_4", {image = "tech_paint_scr_4.png"})
grafitti.register_grafitti("tech:scr_5", {image = "tech_paint_scr_5.png"})
grafitti.register_grafitti("tech:scr_down", {image = "tech_paint_scr_down.png"})
grafitti.register_grafitti("tech:scr_left", {image = "tech_paint_scr_left.png"})
grafitti.register_grafitti("tech:scr_n", {image = "tech_paint_scr_n.png"})
grafitti.register_grafitti("tech:scr_right", {image = "tech_paint_scr_right.png"})
grafitti.register_grafitti("tech:scr_u", {image = "tech_paint_scr_u.png"})
grafitti.register_grafitti("tech:scr_up", {image = "tech_paint_scr_up.png"})

grafitti.palette_build("tech:scratching")

grafitti.register_brush("tech:stone_etcher", {
    description = S("Stone Etcher"),
    inventory_image = "tech_paint_scratcher.png",
    wield_image = "tech_paint_scratcher.png^[transformR270",
    palette = "tech:scratching"
})

minetest.override_item("tech:stone_etcher", {
	_use_tip = "Flip to stone knife",
	_on_use_item = function(player, wielded_item, pointed_thing)
	   local wear = wielded_item:get_wear()
	   local knife = ItemStack("tech:stone_chopper")
	   knife:set_wear(wear)
	   player:set_wielded_item(knife)
	end
})


----------------------------------------------------------
--carbon black



----------------------------------------------------------
--red ochre

local ochre = "^[colorize:#8f5136"

local ograffiti = { "lw_axe",
		    "lw_birdstanding",
		    "lw_dot",
		    "lw_figure_block",
		    "lw_figure_running",
		    "lw_figure_tool",
		    "lw_fire",
		    "lw_fish",
		    "lw_fruit",
		    "lw_house",
		    "lw_insect",
		    "lw_ladder",
		    "lw_pickaxe",
		    "lw_pot",
		    "lw_shovel",
		    "lw_spider",
		    "lw_spiral2",	    "lw_spirald2",
		    "lw_spirald",	    "lw_spiral",
		    "lw_torch",
		    "lw_tree",
		    "lw_water",
		    "lw_weave",
		    "wh_arrow_back",
		    "wh_arrow_down",
		    "wh_arrow_forward",
		    "wh_arrow_left",
		    "wh_arrow_right",
		    "wh_arrow_twoway",
		    "wh_arrow_up",
		    "wh_bed",
		    "wh_fire",
		    "wh_house",
		    "wh_kiln",
		    "wh_ladder",
		    "wh_moon",
		    "wh_sun",
		    "wh_pottery",
		    "wh_shelter",
		    "wh_stairs",
		    "wh_water"
}

for i, name in ipairs(ograffiti) do
   grafitti.register_grafitti("tech:"..name,
			      { image = "tech_paint_"..name..".png"..ochre})
end

grafitti.palette_build("tech:ochre_red")

grafitti.register_brush("tech:paint_ochre_red", {
    description = S("Painting Kit (ochre red)"),
    inventory_image = "tech_paint_brush_ochre.png",
    wield_image = "tech_paint_brush_ochre.png^[transformR270",
    palette = "tech:ochre_red"
})

crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:paint_ochre_red",
	items = {'nodes_nature:red_ochre', 'tech:stick', 'group:fibrous_plant 4', 'tech:vegetable_oil 4'},
	level = 1,
	always_known = true,
})
