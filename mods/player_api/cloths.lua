local S = minetest.get_translator("player_api")

-- clothes groups definitions --------------------------------------------------

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

-- Exile clothing was stored as a metadata string, migrate to new inv
local function load_clothing_metadata(player)    
    local player_inv = player:get_inventory()
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
    load_clothing_metadata(player)
    -- this part is to migrate from old "cloths" inventory to separated ones
    local cloths_list = pinv:get_list("cloths")
    if cloths_list then
        -- erased new inventory if there is any
        for index,stack in ipairs(cloths_list) do
            if stack and stack ~= ItemStack("") then
                local slot_nb = minimal.is_group(stack:get_name(),"cloth")
                if slot_nb then
                    pinv:set_stack(player_api.get_inv_name_from_group(slot_nb),1, stack)
                end
            end
        end 
        -- delete list
        pinv:set_size("cloths", 0)
    end 
end

-- Create the "clothes" inventories
function player_api.set_cloths(player)
    local inv = player:get_inventory()
    --dealing with old players part : --
    migrate_cloths(player, inv)                           
    -- only used to move clothes with shift  
    inv:set_size("temp_slot",1)
    inv:set_stack("temp_slot",1,ItemStack(""))  
    -- new invetories
    for _,group in ipairs(cloth_groups) do 
        local name = group["name"]
        if not inv:get_list(name) then
            inv:set_size(name,1)
        end
    end
    player_api.set_texture(player)
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
                        
-- temperatures dealing --------------------------------------------------------
player_api.update_temp = function(player)
    -- set clothing and update comfortable temperature range
    --[[
        clothing temp_min: subtracted from minimum temperature tolerance
        clothing temp_max: added to maximum temperature tolerance

        e.g. if current comfort range is 21 to 35 then...
        temp_min: 6
        temp_max: -8
        new range = 15 to 28 (e.g. you put on a warm coat)

        note: ranges are
        -comfort zone: no energy drain
        -stress zone: some energy drain
        -danger zone: large energy drain
        -extreme zone: direct damage

    ]]

    -- default range, no clothes yet

    local defaults = HEALTH.get_default_attributes()
    local temp_min = assert(defaults.clothing_temp_min)
    local temp_max = assert(defaults.clothing_temp_max)

    if not player then
        return
    end
    local inv = player:get_inventory()
    local armorgroups = {fleshy = 100}
    for _, name in ipairs(player_api.get_inv_names()) do
        local stack = inv:get_stack(name, 1)
        if stack:get_count() == 1 then -- should always be the case
            local def = stack:get_definition()
            -- set comfortable temperature range
            if def.temp_min and def.temp_max then
                temp_min = temp_min - def.temp_min
                temp_max = temp_max + def.temp_max
            end
            if def.adminclothes then
                armorgroups.immortal = 1
            end
            if def.armor then
                armorgroups.fleshy = armorgroups.fleshy - def.armor
            end
        end
    end
    -- apply new temperature comfort range
    local meta = player:get_meta()
    meta:set_int("clothing_temp_min", temp_min)
    meta:set_int("clothing_temp_max", temp_max )
    sfinv.set_player_inventory_formspec(player)
    -- Apply armorgroups changes
    if minetest.settings:get_bool("enable_damage") then
        player:set_armor_groups(armorgroups)
    end
end

function player_api.update_player(player)
    if not minetest.is_player(player) then
        return
    end
    player_api.set_texture(player)
    player_api.update_temp(player)
end

-- cloth composing -------------------------------------------------------------
local cloth_pos = {
    "48,0",
    "32,32",
    "0,32",
    "0,32",
    "0,0",
    "0,32",
}

-- not sure what it does...
function player_api.compose_cloth(player)
    if not minetest.is_player(player) then print("NOT A PLAYER") return end
    local gender = player_api.get_gender(player)
    local inv = player:get_inventory()
    local upper_ItemStack, lower_ItemStack, footwear_ItemStack, head_ItemStack, cape_ItemStack, blanket_ItemStack
    local underwear = false
    local bra = false
    local attached_cloth = {}
    local blanket = false
    
    for _, name in ipairs(player_api.get_inv_names()) do
        local stack = inv:get_stack(name, 1)
        local item_name = stack:get_name()
        local cloth_itemstack = minetest.registered_items[item_name]
        --minetest.chat_send_all(item_name)
        local cloth_type = minetest.get_item_group(item_name, "cloth")
        --if cloth_type then minetest.chat_send_all(cloth_type) end
        local color = ""
        local indx = stack:get_meta():get_int("palette_index") / 8
        local dye = dye_to_colorstring(indx)
        if indx and indx > 0 and not ( dye == "" ) then
            color = "\\^\\[multiply\\:\\"..dye
        end
        if cloth_type == 1 then
            head_ItemStack = cloth_itemstack._cloth_texture..color
        elseif cloth_type == 2 then
            upper_ItemStack = cloth_itemstack._cloth_texture..color
            bra = true
        elseif cloth_type == 3 then
            lower_ItemStack = cloth_itemstack._cloth_texture..color
            underwear = true
        elseif cloth_type == 4 then
            footwear_ItemStack = cloth_itemstack._cloth_texture..color
        elseif cloth_type == 5 then
            cape_ItemStack = cloth_itemstack._cloth_texture..color
        elseif cloth_type == 6 then
            blanket_ItemStack = cloth_itemstack._cloth_texture..color
            blanket = true
        end
        if cloth_itemstack and cloth_itemstack._cloth_attach then
            attached_cloth[#attached_cloth+1] = cloth_itemstack._cloth_attach
        end
    end
    local naked = false
    if not(bra) and gender == "female" then
        upper_ItemStack = "cloth_upper_underwear_default.png"
    end
    if not(underwear) then
        lower_ItemStack = "cloth_lower_underwear_default.png"
        naked = true
    end
    local st = player_api.get_state(player)
    if naked == true and blanket == false then
        st:add_basic("naked", S("Naked"))
    elseif st:is("naked") then
        st:clear("naked")
    end
    local base_texture = player_api.compose_base_texture(
        player, {
            canvas_size ="128x64",
            skin_texture = "player_skin.png",
            eyebrowns_pos = "16,16",
            eye_right_pos = "18,20",
            eye_left_pos = "26,24",
            mouth_pos = "16,28",
            hair_preview = false,
            hair_pos = "0,0",
    })
    local cloth = base_texture.."^".."[combine:128x64"
    if head_ItemStack then
        cloth = cloth .. ":"..cloth_pos[1].."="..head_ItemStack
    end
    if upper_ItemStack then
        cloth = cloth .. ":"..cloth_pos[2].."="..upper_ItemStack
    end
    if lower_ItemStack then
        cloth = cloth .. ":"..cloth_pos[3].."="..lower_ItemStack
    end
    if footwear_ItemStack then
        cloth = cloth .. ":"..cloth_pos[4].."="..footwear_ItemStack
    end
    if cape_ItemStack then
        cloth = cloth .. ":"..cloth_pos[5].."="..cape_ItemStack
    end
    if blanket_ItemStack then
        cloth = cloth .. ":"..cloth_pos[6].."="..blanket_ItemStack
    end
    --Now attached cloth
    if not(next(attached_cloth) == nil) then
        for i = 1, #attached_cloth do
            local attached_item_name = attached_cloth[i]
            local attached_itemstack =
                minetest.registered_items[attached_item_name]
            local attached_cloth_type =
                minetest.get_item_group(attached_item_name, "cloth")
            cloth = cloth .. ":"..cloth_pos[attached_cloth_type]..
                "="..attached_itemstack._cloth_texture
        end
    end
    return cloth
end

-- move cloth from and to inventory --------------------------------------------

-- refuses or accept move to clothing slots
local function allow_move_to_cloth (player, inventory, from_list, from_index)
    local stack = inventory:get_stack(from_list, from_index)
    if stack then                
        local item_group = minimal.is_group(stack:get_name(),"cloth")
        -- refuse the move if not a cloth
        if not item_group then
            return 0
        else
            -- refuse if this is a blanket and I am not in bed
            if item_group == 6 and player_api.get_state(player, "health"):is("resting") == false then  
                minetest.chat_send_player(player:get_player_name(), S("You can't equip a blanket outside of a bed."))              
                return 0
            -- If this is a cloth I am already wearing the same thing                
            elseif inventory:get_stack(cloth_groups[item_group]["name"], 1):get_name() == stack:get_name() then
                minetest.chat_send_player(player:get_player_name(), S("You already wear that!"))
                return 0 
            -- else allow 1
            else
                return 1
            end
        end
    end
end

-- decide what to allow as inventory actions with clothes
minetest.register_allow_player_inventory_action(
function(player, action,inventory, inventory_info)
    -- close old cloths
    -- used for shift click, cloths as transitory inv
    if inventory_info.to_list == "temp_slot" then 
        if action == "move" then  
            if allow_move_to_cloth(player, inventory, inventory_info.from_list, inventory_info.from_index) == 0 then
                return 0
            else
                -- (if I allow only 1, shift-click process will repeat it anyway    untile it did the whole stack)
                return
            end
        end
    end 
    
    -- if destination is a cloth inventory
    for group,t in ipairs(cloth_groups) do
        local name = t["name"]
        if  inventory_info.to_list ==  name then
            if action == "move" then      
                return allow_move_to_cloth(player, inventory, inventory_info.from_list, inventory_info.from_index)
            end
        end
    end
    -- in any other cases, allow the action
    return -- I am not sure about that return (useful ?)
end)

local function equip_with_shift_redirect(player, inventory, from_list, from_index)
    local stack = inventory:get_stack("temp_slot", 1)
    -- if stack bigger than 1, give back the rest to the source 
    local too_much = stack:get_count()-1
    if too_much>0 then
        local give_back = stack:take_item(too_much)
        inventory:set_stack(from_list,from_index, give_back)
    end
    -- at this step we checked before that has a correct cloth group
    -- and there is only 1 item in stack
    local item_group = minimal.is_group(stack:get_name(),"cloth")
    local destination = player_api.get_inv_name_from_group(item_group)
    -- take cloth already in spot if there is some
    local in_dest = inventory:get_stack(destination, 1)
    -- replacing it with new cloth
    inventory:set_stack(destination,1,stack)
    -- returning old cloth to source, or on the ground if no room
    if inventory:room_for_item(from_list,in_dest) then
        inventory:add_item(from_list,in_dest)
    else
        minetest.item_drop(in_dest, player, player:get_pos())
        minetest.chat_send_player(player:get_player_name(),S("Inventory is full : the clothing you wore was thrown on the floor."))
    end
    -- empty cloths slot
    inventory:set_stack("temp_slot",1,ItemStack(""))
    -- update texture and temp settings
    player_api.update_player(player)
end

-- update player settings if cloths change
minetest.register_on_player_inventory_action(function(player, action,
    inventory, inventory_info)
    local from_list = inventory_info.from_list
    local to_list = inventory_info.to_list
    -- update player settings if we add/remove cloths
    for _, group in ipairs(cloth_groups) do
        if from_list == group["name"] or to_list == group["name"] then
            -- update texture and temp settings
            player_api.update_player(player)
            break
        end
    end    
    -- if shift click brought item from inventory to be redirected
    if to_list == "temp_slot" then
        equip_with_shift_redirect(player,inventory, from_list, inventory_info.from_index)
    end          
end)

-- This is used to equip cloths from HUD main inventory with right click
-- the player move the arms until I rotate... #TODO ?
function player_api.on_rightclick(itemstack, user, pointed_thing)
    -- deletes items (or reproduces if programmed differently - gotta fix)
    if not (minetest.is_player(user) and itemstack) then
        return
    end
    
    local item_group = minimal.is_group(itemstack:get_name(),"cloth")
    -- if item is not a clothing or a blanket, do nothing
    if (not item_group or item_group == 6) then
        return
    end
    -- else, itemstack is a clothing. Pich one of them
    local new_cloth = itemstack:take_item()
    -- check correct destination
    local p_inv = user:get_inventory()
    local destination = player_api.get_inv_name_from_group(item_group)
    -- if nothing in here, just put the picked clothing in it
    if p_inv:is_empty(destination) then
        p_inv:add_item(destination, new_cloth)
        minetest.chat_send_player(user:get_player_name(), new_cloth:get_short_description().. " " .. S("equipped!"))
    -- else gets what is in here for an exchange
    else
        local in_dest = p_inv:get_stack(destination, 1)
        -- check that count is 1 (should always be the case, but...)
        if in_dest:get_count()>1 then
            minetest.log("We should have more than 1 clothing in that slot !")
        end
        -- check if this is the same clothing, if yes do nothing
        if new_cloth:equals(in_dest) then
            minetest.chat_send_player(user:get_player_name(), S("You already wear the same cloth."))
            -- don't return itemstack to not modify the source itemstack
            return
        else
            -- put new clothing in destination
            p_inv:set_stack(destination,1,new_cloth)
            minetest.chat_send_player(user:get_player_name(), new_cloth:get_short_description().. " " .. S("equipped!"))
            -- returning old cloth to source, or on the ground if no room
            -- warning, inv itemstack is updated only after end of call, so room is not free before
            if (itemstack:get_count() == 0) then
                  -- if this stack is about to be cleared... return in_dest, it will be added to inventory at the end of the call
                  itemstack = in_dest
            elseif p_inv:room_for_item("main",in_dest) then 
                p_inv:add_item("main",in_dest)               
            else
                minetest.item_drop(in_dest, user, user:get_pos())
                minetest.chat_send_player(user:get_player_name(),S("Inventory is full : the clothing you wore was thrown on the floor."))
            end
        end
    end
    -- update player settings
    player_api.update_player(user)
    return itemstack
end
