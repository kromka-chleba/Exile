----------------------------------------------------------

clothing = clothing

clothing.update_temp = function(self, player)
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
   local temp_min = 20
   local temp_max = 30

   if not player then
		return
	end
	local inv = player:get_inventory():get_list("cloths")
	local armorgroups = {fleshy = 100}
	for i=1, #inv do
		local stack = ItemStack(inv[i])
		if stack:get_count() == 1 then
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
	if minetest.settings:get_bool("enable_damage") then player:set_armor_groups(armorgroups) end
end

function clothing.update_player(player)
  if not minetest.is_player(player) then
    return
  end
  clothing:update_temp(player)
  player_api.set_texture(player)
end

function clothing.update_clothing_inventory(player, stack, oldinv_name)
  if not (minetest.is_player(player) and type(oldinv_name) == "string" and stack) then
    -- was not a player or did not get a proper string for "oldinv_name" or stack does not exist
    return false
  end
  
  local item_group = minimal.in_group(stack:get_name(),"cloth")
  if not item_group -- not a cloth
  or item_group == 6 then -- is a blanket
    return false
  end
  
  local player_inv = player:get_inventory()
  local cloth_list = player_inv:get_list("cloths")
  
  for _,itemstack in pairs(cloth_list) do
    local cloth_name = itemstack:get_name()
    if (minimal.in_group(cloth_name,"cloth") == item_group) then
      -- if same type of clothing article found then
      if (oldinv_name == "main") then -- if new itemstack is coming from player inventory
        local removed = player_inv:remove_item("cloths", itemstack) -- take the old itemstack
        if player_inv:room_for_item(oldinv_name,removed) then
          -- add to player inventory
          player_inv:add_item(oldinv_name,removed)
          return true
        else
          -- throw it to the ground
          minetest.item_drop(removed, player, player:get_pos())
        end
      end
    end
  end
  return true
end

function clothing.uci_itemstack(itemstack, user, pointed_thing)
  -- deletes items (or reproduces if programmed differently - gotta fix)
  --[[
  if clothing.update_clothing_inventory(user, itemstack, "main") then
    local player_inv = user:get_inventory()
    local taken = itemstack:take_item()
    minetest.log(""..taken:get_count()..":"..itemstack:get_count())
    player_inv:add_item("cloths",taken)
    return itemstack
  else
    return
  end
  --]]
end