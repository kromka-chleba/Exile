----------------------------------------------------------
--Grafitti
--uses api for registering various painted images
--various symbols and patterns, enough to make it possible to form a symbolic vocabulary.

--colours:
-- simple scratching with stone
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


--abstract
grafitti.register_grafitti("tech:lw_x", {image = "tech_paint_lw_x.png"})
grafitti.register_grafitti("tech:lw_hourglass1", {image = "tech_paint_lw_hourglass1.png"})
grafitti.register_grafitti("tech:lw_hourglass2", {image = "tech_paint_lw_hourglass2.png"})
grafitti.register_grafitti("tech:lw_hourglass3", {image = "tech_paint_lw_hourglass3.png"})
grafitti.register_grafitti("tech:lw_xox", {image = "tech_paint_lw_xox.png"})

grafitti.register_grafitti("tech:lw_o", {image = "tech_paint_lw_o.png"})
grafitti.register_grafitti("tech:lw_odot", {image = "tech_paint_lw_odot.png"})

grafitti.register_grafitti("tech:lw_quad", {image = "tech_paint_lw_quad.png"})
grafitti.register_grafitti("tech:lw_quaddot", {image = "tech_paint_lw_quaddot.png"})

grafitti.register_grafitti("tech:lw_oval", {image = "tech_paint_lw_oval.png"})
grafitti.register_grafitti("tech:lw_ovalfull", {image = "tech_paint_lw_ovalfull.png"})

grafitti.register_grafitti("tech:lw_square", {image = "tech_paint_lw_square.png"})
grafitti.register_grafitti("tech:lw_squarefull", {image = "tech_paint_lw_squarefull.png"})

grafitti.register_grafitti("tech:lw_lineh", {image = "tech_paint_lw_lineh.png"})
grafitti.register_grafitti("tech:lw_linev", {image = "tech_paint_lw_linev.png"})
grafitti.register_grafitti("tech:lw_flute", {image = "tech_paint_lw_flute.png"})

grafitti.register_grafitti("tech:lw_arrowd", {image = "tech_paint_lw_arrowd.png"})
grafitti.register_grafitti("tech:lw_arrowu", {image = "tech_paint_lw_arrowu.png"})
grafitti.register_grafitti("tech:lw_arrowl", {image = "tech_paint_lw_arrowl.png"})
grafitti.register_grafitti("tech:lw_arrowr", {image = "tech_paint_lw_arrowr.png"})

grafitti.register_grafitti("tech:lw_penni1", {image = "tech_paint_lw_penni1.png"})
grafitti.register_grafitti("tech:lw_penni2", {image = "tech_paint_lw_penni2.png"})
grafitti.register_grafitti("tech:lw_pecti1", {image = "tech_paint_lw_pecti1.png"})
grafitti.register_grafitti("tech:lw_pecti2", {image = "tech_paint_lw_pecti2.png"})
grafitti.register_grafitti("tech:lw_tecti", {image = "tech_paint_lw_tecti.png"})
grafitti.register_grafitti("tech:lw_4pole", {image = "tech_paint_lw_4pole.png"})
grafitti.register_grafitti("tech:lw_avi", {image = "tech_paint_lw_avi.png"})
grafitti.register_grafitti("tech:lw_scali", {image = "tech_paint_lw_scali.png"})
grafitti.register_grafitti("tech:lw_bridge", {image = "tech_paint_lw_bridge.png"})

grafitti.register_grafitti("tech:lw_spiral", {image = "tech_paint_lw_spiral.png"})
grafitti.register_grafitti("tech:lw_spiral2", {image = "tech_paint_lw_spiral2.png"})
grafitti.register_grafitti("tech:lw_spirald", {image = "tech_paint_lw_spirald.png"})
grafitti.register_grafitti("tech:lw_spirald2", {image = "tech_paint_lw_spirald2.png"})
grafitti.register_grafitti("tech:lw_antiq", {image = "tech_paint_lw_antiq.png"})

grafitti.register_grafitti("tech:lw_burst1", {image = "tech_paint_lw_burst1.png"})
grafitti.register_grafitti("tech:lw_burst2", {image = "tech_paint_lw_burst2.png"})
grafitti.register_grafitti("tech:lw_bolt", {image = "tech_paint_lw_bolt.png"})

--less abstract
grafitti.register_grafitti("tech:lw_tree", {image = "tech_paint_lw_tree.png"})
grafitti.register_grafitti("tech:lw_hand", {image = "tech_paint_lw_hand.png"})
grafitti.register_grafitti("tech:lw_hand2", {image = "tech_paint_lw_hand2.png"})
grafitti.register_grafitti("tech:lw_foot", {image = "tech_paint_lw_foot.png"})
grafitti.register_grafitti("tech:lw_fig1", {image = "tech_paint_lw_fig1.png"})
grafitti.register_grafitti("tech:lw_fig2", {image = "tech_paint_lw_fig2.png"})
grafitti.register_grafitti("tech:lw_fig3", {image = "tech_paint_lw_fig3.png"})
grafitti.register_grafitti("tech:lw_chrysalis", {image = "tech_paint_lw_chrysalis.png"})

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
--carbon black

grafitti.register_grafitti("tech:cb_a", {image = "tech_paint_cb_a.png"})
grafitti.register_grafitti("tech:cb_b", {image = "tech_paint_cb_b.png"})
grafitti.register_grafitti("tech:cb_k", {image = "tech_paint_cb_k.png"})
grafitti.register_grafitti("tech:cb_d", {image = "tech_paint_cb_d.png"})
grafitti.register_grafitti("tech:cb_i", {image = "tech_paint_cb_i.png"})
grafitti.register_grafitti("tech:cb_f", {image = "tech_paint_cb_f.png"})
grafitti.register_grafitti("tech:cb_g", {image = "tech_paint_cb_g.png"})
grafitti.register_grafitti("tech:cb_h", {image = "tech_paint_cb_h.png"})
grafitti.register_grafitti("tech:cb_ii", {image = "tech_paint_cb_ii.png"})
grafitti.register_grafitti("tech:cb_j", {image = "tech_paint_cb_j.png"})
grafitti.register_grafitti("tech:cb_ng", {image = "tech_paint_cb_ng.png"})
grafitti.register_grafitti("tech:cb_l", {image = "tech_paint_cb_l.png"})
grafitti.register_grafitti("tech:cb_m", {image = "tech_paint_cb_m.png"})
grafitti.register_grafitti("tech:cb_n", {image = "tech_paint_cb_n.png"})
grafitti.register_grafitti("tech:cb_u", {image = "tech_paint_cb_u.png"})
grafitti.register_grafitti("tech:cb_p", {image = "tech_paint_cb_p.png"})
grafitti.register_grafitti("tech:cb_r", {image = "tech_paint_cb_r.png"})
grafitti.register_grafitti("tech:cb_s", {image = "tech_paint_cb_s.png"})
grafitti.register_grafitti("tech:cb_t", {image = "tech_paint_cb_t.png"})
grafitti.register_grafitti("tech:cb_uu", {image = "tech_paint_cb_uu.png"})
grafitti.register_grafitti("tech:cb_v", {image = "tech_paint_cb_v.png"})
grafitti.register_grafitti("tech:cb_ee", {image = "tech_paint_cb_ee.png"})
grafitti.register_grafitti("tech:cb_oh", {image = "tech_paint_cb_oh.png"})
grafitti.register_grafitti("tech:cb_ur", {image = "tech_paint_cb_ur.png"})
grafitti.register_grafitti("tech:cb_th", {image = "tech_paint_cb_th.png"})
grafitti.register_grafitti("tech:cb_R", {image = "tech_paint_cb_R.png"})

grafitti.palette_build("tech:carbon_black")

grafitti.register_brush("tech:paint_carbon_black", {
    description = S("Painting Kit (carbon black)"),
    inventory_image = "tech_paint_brush_carbon.png",
    wield_image = "tech_paint_brush_carbon.png^[transformR270",
    palette = "tech:carbon_black"
})


crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:paint_carbon_black",
	items = {'tech:charcoal 16', 'tech:stick', 'group:fibrous_plant 4', 'tech:vegetable_oil 4'},
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
grafitti.register_grafitti("tech:scr_U", {image = "tech_paint_scr_U.png"})
grafitti.register_grafitti("tech:scr_up", {image = "tech_paint_scr_up.png"})

grafitti.palette_build("tech:scratching")

grafitti.register_brush("tech:paint_scratching", {
    description = S("Painting Kit (scratching)"),
    inventory_image = "tech_paint_scratcher.png",
    wield_image = "tech_paint_scratcher.png^[transformR270",
    palette = "tech:scratching"
})


crafting.register_recipe({
	type = "crafting_spot",
	output = "tech:paint_scratching",
	items = {'group:basalt_cobble 2'},
	level = 1,
	always_known = true,
})







----------------------------------------------------------
--red ochre
