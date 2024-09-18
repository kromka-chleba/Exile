----------------------------------------------------------
--CLOTHING 
--This file only defines clothes and their recipe

-- Internationalization
local S = tech.S

local cloth_stack_max = minimal.stack_max_bulky

-- Register function in player_api/cloths.lua, groups[cloth] codes are :
-- 1 = Head, 2 = Upper, 3 = Lower, 4 = Footwear, 5 = Cape, 6 = Blanket

----------------------------------------------------------------
--PRIMITIVE
--from crude woven fibres,

--Hat
player_api.register_cloth(
    "tech:woven_hat", {
        description = S("Woven Hat"),
        inventory_image = "tech_inv_woven_hat.png",
        texture = "tech_uv_woven_hat.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 1}, -- Hat
        customfields= {temp_min = 1, temp_max = 1}
})

crafting.register_recipe({
        type = "weaving_frame",
        output = "tech:woven_hat",
        items = {'group:fibrous_plant 24'},
        level = 1,
        always_known = true,
})


--Sun Hat
player_api.register_cloth(
    "tech:sun_hat", {
        description = S("Sun Hat"),
        inventory_image = "tech_inv_sun_hat.png",
        texture = "tech_uv_sun_hat.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 1}, -- Hat
        customfields= {temp_min = 0, temp_max = 2}
})

crafting.register_recipe({
        type = "weaving_frame",
        output = "tech:sun_hat",
        items = {'group:fibrous_plant 24'},
        level = 1,
        always_known = true,
})


--Sandals
player_api.register_cloth(
    "tech:woven_sandals", {
        description = S("Woven Sandals"),
        inventory_image = "tech_inv_woven_sandals.png",
        texture = "tech_uv_woven_sandals.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 4},
        customfields= {temp_min = 1, temp_max = 1}
})


crafting.register_recipe({
        type = "weaving_frame",
        output = "tech:woven_sandals",
        items = {'group:fibrous_plant 24'},
        level = 1,
        always_known = true,
})


--Cape
player_api.register_cloth(
    "tech:woven_cape", {
        description = S("Woven Cape"),
        inventory_image = "tech_inv_woven_cape.png",
        texture = "tech_uv_woven_cape.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 5},
        customfields= {temp_min = 2, temp_max = 1}
})

crafting.register_recipe({
        type = "weaving_frame",
        output = "tech:woven_cape",
        items = {'group:fibrous_plant 48'},
        level = 1,
        always_known = true,
})


--Poncho
player_api.register_cloth(
    "tech:woven_poncho", {
        description = S("Woven Poncho"),
        inventory_image = "tech_inv_woven_poncho.png",
        texture = "tech_uv_woven_poncho.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 2},
        customfields= {temp_min = 2, temp_max = 1}
})

crafting.register_recipe({
        type = "weaving_frame",
        output = "tech:woven_poncho",
        items = {'group:fibrous_plant 48'},
        level = 1,
        always_known = true,
})


--Leggings
player_api.register_cloth(
    "tech:woven_leggings", {
        description = S("Woven Leggings"),
        inventory_image = "tech_inv_woven_leggings.png",
        texture = "tech_uv_woven_leggings.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 3},
        customfields= {temp_min = 1, temp_max = 0}
})

crafting.register_recipe({
        type = "weaving_frame",
        output = "tech:woven_leggings",
        items = {'group:fibrous_plant 36'},
        level = 1,
        always_known = true,
})

--Blanket
player_api.register_cloth(
    "tech:woven_blanket", {
        description = S("Woven Blanket"),
        inventory_image = "tech_woven_blanket_thumb.png",
        texture = "tech_woven_blanket.png",
        stack_max = cloth_stack_max,
        groups = {blanket=1, cloth=6}, -- #TODO cloth =6 and blanket = 1 means EXACTLY the same right now, we could simplify that, especially since cloth=6 is an expetion in each cloths.lua function. code 6 is used in temperature managementn bleket in finding blanket
        customfields = {temp_min = 3, temp_max = -2}
})
crafting.register_recipe({
        type = "weaving_frame",
        output = "tech:woven_blanket",
        items = {'group:fibrous_plant 60'},
        level = 1,
        always_known = true,
})


----------------------------------------------------------------
--FABRIC
--from loom woven fabric
--two types:
-- thick: better for winter, but needs more material, bad in summer
--light: better for summer

--Light Hat
player_api.register_cloth(
    "tech:light_fabric_hat", {
        description = S("Light Fabric Hat"),
        inventory_image = "tech_inv_light_fabric_hat.png",
        texture = "tech_uv_light_fabric_hat.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 1}, -- Hat
        customfields= {temp_min = 2, temp_max = 1}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:light_fabric_hat",
        items = {'tech:fine_fabric'},
        level = 1,
        always_known = true,
})


--Thick Hat
player_api.register_cloth(
    "tech:thick_fabric_hat", {
        description = S("Thick Fabric Hat"),
        inventory_image = "tech_inv_thick_fabric_hat.png",
        texture = "tech_uv_thick_fabric_hat.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 1}, -- Hat
        customfields= {temp_min = 4, temp_max = -1}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:thick_fabric_hat",
        items = {'tech:fine_fabric 2'},
        level = 1,
        always_known = true,
})


--light Cape
player_api.register_cloth(
    "tech:light_fabric_cape", {
        description = S("Light Fabric Cape"),
        inventory_image = "tech_inv_light_fabric_cape.png",
        texture = "tech_uv_light_fabric_cape.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 5}, -- Cape
        customfields= {temp_min = 3, temp_max = 3}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:light_fabric_cape",
        items = {'tech:fine_fabric 3'},
        level = 1,
        always_known = true,
})

--Thick Cape
player_api.register_cloth(
    "tech:thick_fabric_cape", {
        description = S("Thick Fabric Cape"),
        inventory_image = "tech_inv_thick_fabric_cape.png",
        texture = "tech_uv_thick_fabric_cape.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 5}, -- Cape
        customfields= {temp_min = 6, temp_max = -2}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:thick_fabric_cape",
        items = {'tech:fine_fabric 6'},
        level = 1,
        always_known = true,
})


--Light Trousers
player_api.register_cloth(
    "tech:light_fabric_trousers", {
        description = S("Light Fabric Trousers"),
        inventory_image = "tech_inv_light_fabric_trousers.png",
        texture = "tech_uv_light_fabric_trousers.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 3}, -- Lower Part
        customfields= {temp_min = 3, temp_max = 2}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:light_fabric_trousers",
        items = {'tech:fine_fabric 4'},
        level = 1,
        always_known = true,
})


--Thick Trousers
player_api.register_cloth(
    "tech:thick_fabric_trousers", {
        description = S("Thick Fabric Trousers"),
        inventory_image = "tech_inv_thick_fabric_trousers.png",
        texture = "tech_uv_thick_fabric_trousers.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 3}, -- Lower Part
        customfields= {temp_min = 6, temp_max = -2}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:thick_fabric_trousers",
        items = {'tech:fine_fabric 8'},
        level = 1,
        always_known = true,
})


--Light Tunic
player_api.register_cloth(
    "tech:light_fabric_tunic", {
        description = S("Light Fabric Tunic"),
        inventory_image = "tech_inv_light_fabric_tunic.png",
        texture = "tech_uv_light_fabric_tunic.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 2}, -- Upper part
        customfields= {temp_min = 3, temp_max = 2}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:light_fabric_tunic",
        items = {'tech:fine_fabric 4'},
        level = 1,
        always_known = true,
})


--Thick Tunic
player_api.register_cloth(
    "tech:thick_fabric_tunic", {
        description = S("Thick Fabric Tunic"),
        inventory_image = "tech_inv_thick_fabric_tunic.png",
        texture = "tech_uv_thick_fabric_tunic.png",
        stack_max = cloth_stack_max,
        groups = {cloth = 2}, -- Upper part
        customfields= {temp_min = 6, temp_max = -2}
})

crafting.register_recipe({
        type = "loom",
        output = "tech:thick_fabric_tunic",
        items = {'tech:fine_fabric 8'},
        level = 1,
        always_known = true,
})
