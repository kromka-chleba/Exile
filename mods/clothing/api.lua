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

function clothing.on_rightclick(itemstack, user, pointed_thing)
  -- deletes items (or reproduces if programmed differently - gotta fix)
  if not (minetest.is_player(user) and itemstack) then
    return
  end
  
  local item_group = minimal.in_group(itemstack:get_name(),"cloth")
  if (not item_group or item_group == 6) then
    return
  end
  local player_inv = user:get_inventory() 
  local cloth_list = player_inv:get_list("cloths")
  
  local new_cloth = itemstack:take_item() -- take the cloth from itemstack (prevent weird itemstack interactions)
  -- check for another similar cloth
  for _,cloth in pairs(cloth_list) do
    local cloth_name = cloth:get_name()
    if (minimal.in_group(cloth_name,"cloth") == item_group) then
      -- if same type of clothing article found then
      local removed = player_inv:remove_item("cloths", cloth) -- take the old cloth
      -- if there's enough room for the removed cloth to be added to player inv
      if player_inv:room_for_item("main",removed) then
        -- add to player inventory (and prevent weird hat reproduction or deletion by checking itemstack count)
        if (itemstack:get_count() == 0) then
          -- if this stack is about to be cleared... return itemstack instead
          itemstack = removed
        else
          player_inv:add_item("main",removed)
        end
      else
        -- otherwise throw it to the ground
        minetest.item_drop(removed, user, user:get_pos())
      end
      break
    end
  end
  
  -- add new_cloth to cloth inventory
  if player_inv:room_for_item("cloths",new_cloth) then
    player_inv:add_item("cloths",new_cloth)
  else
    -- something went terribly wrong... drop the cloth
    minetest.item_drop(new_cloth,user, user:get_pos())
  end
  
  clothing.update_player(user)
  
  return itemstack
end