-- clothes groups definitions --------------------------------------------------

-- Internationalization---------------------------------------------------------
local S = minetest.get_translator("player_api")
--------------------------------------------------------------------------------

player_api = player_api

-- defines cloth groups and inventories
-- [groupe_code] = {inv_name, tooltip}
local cloth_groups = {
    [1] = {["name"]="hat", ["tooltip"]= S("Head")},
    [2] = {["name"]="shirt", ["tooltip"]=S("Upper")},
    [3] = {["name"]="pants",  ["tooltip"]=S("Lower")},
    [4] = {["name"]="shoes",  ["tooltip"]=S("Footwear")},
    [5] = {["name"]="cape", ["tooltip"]=S("Cape")},
    [6] = {["name"]="blanket",  ["tooltip"]=S("Keeps you warm in bed")}
}

-- get inv cloth lists
function player_api.get_groups()
    return cloth_groups
end

-- return matching player inventory name with group number
function player_api.get_inv_name_from_group(nb)
	local t = cloth_groups[nb]
	if t then
		return t["name"]
	end
end

function player_api.get_inv_names()
    local t = {}
    for _, group in ipairs(cloth_groups) do
        table.insert(t,group["name"])
	end
    return t
end

-- set tooltip associated to each groups["cloth"] code
local function get_tooltip_from_group (group_nb)
    local group = cloth_groups[group_nb]
    if group then
        return "(" .. group["tooltip"].. ")" or ""
    end
end

-- Create the "clothes" inventories
function player_api.init_cloths(player, pinv)
    local inv = pinv or player:get_inventory()
    -- one inventory per group type
    for _,group in ipairs(cloth_groups) do
        local name = group["name"]
        if not inv:get_list(name) then
            inv:set_size(name,1)
        end
    end
    -- only used to move clothes with shift
    inv:set_size("temp_slot",1)
    inv:set_stack("temp_slot",1,ItemStack(""))

    -- #TODO following to remove when Mantar is done with testing
    do
        if not inv:get_list("cloths") then
            inv:set_size("cloths",6)
        end
    end
end

-- Exile clothing was stored as a metadata string, migrate to new inv
local function load_clothing_metadata(player, player_inv)
    local meta = player:get_meta()
    local clothing_meta = meta:get_string("clothing:inventory")
    local clothes = clothing_meta and minetest.deserialize(clothing_meta) or {}
    if clothing_meta == "" then
        return
    end
    for i = 1, 6 do
        player_inv:set_stack(cloth_groups[i]["name"], 1, clothes[i] or "")
        --overwrite current clothes, but it will be empty on first migration
    end
    meta:set_string("clothing:inventory", "")
end

-- dealing with old cloth inventory versions
local function migrate_cloths(player, pinv)
    --import old clothing
    load_clothing_metadata(player, pinv)
    -- this part is to migrate from old "cloths" inventory to separated ones
    local cloths_list = pinv:get_list("cloths")
    if cloths_list then
        -- erased new inventory if there is any
        for index,stack in ipairs(cloths_list) do
            if stack and stack ~= ItemStack("") then
                local slot_nb = minimal.is_group(stack:get_name(),"cloth")
                if slot_nb then
                    pinv:set_stack(cloth_groups[slot_nb]["name"],1, stack)
                end
            end
        end
        -- delete list
        -- #TODO uncomment following line when Mantar is done with testing
        -- pinv:set_size("cloths", 0)
    end
end

-- init inventories and migrates
function player_api.set_cloths(player)
    local inv = player:get_inventory()
    player_api.init_cloths(player, inv)
    --dealing with old players part : --
    migrate_cloths(player, inv)
end

-- Clothes registering ---------------------------------------------------------

-- Defines how to register clothes
function player_api.register_cloth(name, def)
    if not(def.inventory_image) then
        def.wield_image = def.texture
    end
    if not(def.wield_image) then
        def.wield_image = def.inventory_image
    end
    local tooltip
    local gender, gender_color
    local description
    if not def.attached then
        local cloth_type = def.groups["cloth"]
        if cloth_type then
            tooltip = get_tooltip_from_group (cloth_type)
        end
        if def.gender == "male" then
            gender = S("Male")
            gender_color = "#00baff"
        elseif def.gender == "female" then
            gender = S("Female")
            gender_color = "#ff69b4"
        else
            gender = S("Unisex")
            gender_color = "#9400d3"
        end
        tooltip = tooltip.."\n".. minetest.colorize(gender_color, gender)
        description = def.description .. "\n" .. tooltip
    end
    local newdef = {
        description = description or nil,
        inventory_image = def.inventory_image or nil,
        wield_image = def.wield_image or nil,
        stack_max = def.stack_max or 16, -- #TODO maybe arrange defaults here and not in local variable in clothing
        _cloth_attach = def.attach or nil,
        _cloth_attached = def.attached or false,
        _cloth_texture = def.texture or nil,
        _cloth_preview = def.preview or nil,
        _cloth_gender = def.gender or nil,
        palette = "natural_dyes.png",
        groups = def.groups or nil,
    }
    -- below functions will be added to blankets - but will not have any clothing functionality
    newdef.on_secondary_use = function(itemstack, user, pointed_thing)
        local under = pointed_thing.under
        if under then
            -- "under" will not exist if pointed_thing is not a node
            local nodedef = minimal.get_nodedef(under)
            if nodedef and nodedef.on_rightclick then
                return nodedef.on_rightclick(under, minetest.get_node(under),
                                             user, itemstack, pointed_thing)
            end
        end
        return player_api.on_rightclick(itemstack, user, pointed_thing)
    end
    newdef.on_place = newdef.on_secondary_use -- no point for on_place, make it run on_secondary_use
    if def.customfields then
        for k, d in pairs(def.customfields) do
            newdef[k] = d
        end
    end

    -- updates player cloth effects on dropping
    -- in case this is dropped from cloth inventory in formspec
    newdef.on_drop = function (itemstack, dropper, pos)
        local leftover = minetest.item_drop(itemstack, dropper, pos)
        -- update cloth effects
        minetest.after(0.1, function()
            player_api.update_player(dropper)
            end)
        return leftover
    end

    minetest.register_craftitem(name, newdef)
end

-- Default clothing only needed in creative mod
player_api.register_cloth(
    "player_api:cloth_female_upper_default", {
        description = S("Purple Stripe Summer T-shirt"),
        inventory_image = "cloth_female_upper_default_inv.png",
        wield_image = "cloth_female_upper_default.png",
        texture = "cloth_female_upper_default.png",
        preview = "cloth_female_upper_preview.png",
        gender = "female",
        groups = {cloth = 2},
})

player_api.register_cloth(
    "player_api:cloth_female_lower_default", {
        description = S("Fresh Summer Denim Shorts"),
        inventory_image = "cloth_female_lower_default_inv.png",
        wield_image = "cloth_female_lower_default_inv.png",
        texture = "cloth_female_lower_default.png",
        preview = "cloth_female_lower_preview.png",
        gender = "female",
        groups = {cloth = 3},
})

player_api.register_cloth(
    "player_api:cloth_unisex_footwear_default", {
        description = S("Common Black Shoes"),
        inventory_image = "cloth_unisex_footwear_default_inv.png",
        wield_image = "cloth_unisex_footwear_default_inv.png",
        texture = "cloth_unisex_footwear_default.png",
        preview = "cloth_unisex_footwear_preview.png",
        gender = "unisex",
        groups = {cloth = 4},
})

player_api.register_cloth(
    "player_api:cloth_female_head_default", {
        description = S("Pink Bow"),
        inventory_image = "cloth_female_head_default_inv.png",
        wield_image = "cloth_female_head_default_inv.png",
        texture = "cloth_female_head_default.png",
        preview = "cloth_female_head_preview.png",
        gender = "female",
        groups = {cloth = 1},
})

player_api.register_cloth(
    "player_api:cloth_male_upper_default", {
        description = S("Classic Green Sweater"),
        inventory_image = "cloth_male_upper_default_inv.png",
        wield_image = "cloth_male_upper_default_inv.png",
        texture = "cloth_male_upper_default.png",
        preview = "cloth_male_upper_preview.png",
        gender = "male",
        groups = {cloth = 2},
})

player_api.register_cloth(
    "player_api:cloth_male_lower_default", {
        description = S("Fine Blue Pants"),
        inventory_image = "cloth_male_lower_default_inv.png",
        wield_image = "cloth_male_lower_default_inv.png",
        texture = "cloth_male_lower_default.png",
        preview = "cloth_male_lower_preview.png",
        gender = "male",
        groups = {cloth = 3},
})

--Not available except through creative
minetest.override_item("player_api:cloth_unisex_footwear_default", {
                           temp_min = 50,
                           temp_max = 50,
                           adminclothes = true,
})

minetest.register_alias("admin_shoes",
                        "player_api:cloth_unisex_footwear_default")
