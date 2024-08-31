--
-- Register Egg
--for capturing and respawing unique animals
--

animals = animals
mobkit = mobkit

local S = animals.S

local function math_clamp(...) -- num, min, max
  return minimal.math_clamp(...)
end

local create_mob = function(placer, itemstack, name, pos)
	local meta = itemstack:get_meta()
	local meta_table = meta:to_table()
	local memory
	if meta_table.fields.memory then
		memory=minetest.deserialize(meta_table.fields.memory)

	end
	local sdata = minetest.serialize(meta_table)
	local mob = minetest.add_entity(pos, name, sdata)

	local ent = mob:get_luaentity()
	if memory then
		for key,value in pairs(memory) do
			mobkit.remember(ent,key,value)
		end
	end
  -- if player isn't in creative
  if not (minimal.player_in_creative(placer)) then
    itemstack:take_item() -- since mob is unique we remove egg once spawned
  end
	return ent
end



local pos_to_spawn = function(name, pos)
	local x = pos.x
	local y = pos.y
	local z = pos.z
	local def = minetest.registered_entities[name]
	local props = def.initial_properties
	if not def or not props then return end
	if props.visual_size.x then
		if props.visual_size.x >= 32 and
			props.visual_size.x <= 48 then
				y = y + 2
		elseif props.visual_size.x > 48 then
			y = y + 5
		else
			y = y + 1
		end
	end
	local spawn_pos = { x = x, y = y, z = z}
	return spawn_pos
end


--use stunning weapon plus chance to catch (or if canhand == true)
animals.stun_catch_mob = function(self, clicker, time_from_last_click, tool_capabilities)--,chance,canhand)
  if not clicker or not minetest.is_player(clicker) then return end
	if self.hp <= 0 then return end
	local item = clicker:get_wielded_item()
	local item_name = item:get_name()
  tool_capabilities = type(tool_capabilities) == "table" and tool_capabilities or {full_punch_interval = 1}
  if not self.capture_interactions then
    return false,false -- creature can't be captured + is not captured
  end
  local success_rate
  for group,values in pairs(self.capture_interactions) do
    if (group == "hand" and (item_name == "" or tool_capabilities.is_hand) ) then
      success_rate = values[1] -- it's just a hand, why would there be more options than 1?
      -- empty hand should not have custom capture qualities
      if item_name == "" then
        break
      end
    end
    local itemg = minetest.get_item_group(item_name,group) -- item group
    if itemg ~= 0 then
      -- iterate over table for the best percentage
      for value,perc in pairs(values) do
        if itemg < value then
          -- no possible way this tool will work (item group is less than the provided necessary group)
          break
        else
          -- update success_rate
          if not success_rate or -- define success_rate OR
          (success_rate and perc > success_rate) then -- choose what gives the best chances
            success_rate = perc
          end
        end
      end
    end
  end
  if not success_rate then
    return false,false
  end
  time_from_last_click = type(time_from_last_click) == "number" and time_from_last_click or 1
  -- modify success_rate according to tool_capabilities (if not in creative)
  -- 100% is 100%, you've whacked em good, no need to worry about last click!
  if success_rate < 1 and not minimal.player_in_creative(clicker) then
    success_rate = success_rate * math_clamp(time_from_last_click / tool_capabilities.full_punch_interval, 0, 1)
  end
  if self.hp <= self.max_hp*0.75 then -- if less than 3 quarters of full HP then calculate damage-based capture success
    local damaged_multiplier = math_clamp(1/(self.hp/self.max_hp) * (self.damaged_capture_multiplier or 1),1,math.huge )
    if damaged_multiplier > 0 then -- if 0, do no changes
      success_rate = success_rate * damaged_multiplier
    end
  end
  -- catch chance
  mobkit.make_sound(self,'punch')
  if success_rate >= math.random() then
    -- successful catch
    mobkit.make_sound(self,'punch')
    animals.capture(self, clicker)
    return true,true -- creature can be captured + is captured
  else
    return true,false -- creature can be captured + is not captured
  end
end




-- spawnegg registration, requires the following values:
--[[
stack (itemstack stack_max)
desc (itemstack description)
inv_img (itemstack inventory image)

energy_egg (energy given to egg as a total)
young_per_egg (how many children per egg - used for energy_egg calculation)
class (optional - used to determine if aquatic)
--]]
animals.register_spawnegg = function(self)
   local name = self.name
   assert(type(name) == "string","animals.register_spawnegg: provided self data does not contain a name!")
   local stack = type(self.stack) == "number" and self.stack or 1
   local desc = type(self.desc) == "string" and self.desc or ""
   local inv_img = type(self.inv_img) == "string" and self.inv_img or ""
   local ee = self.energy_egg or 100
   local ype = self.young_per_egg or 1
   local liquids_pointable = false
   if (self.class == 2) then
      liquids_pointable = true
   end
   local item_table = { -- register new spawn egg containing mob information
      description = desc,
      inventory_image = inv_img,
      stack_max = stack,
      groups = {spawn_egg = 1},
      drops = self.drops or {},
      liquids_pointable = liquids_pointable,
      _use_tip = S("Slaughter the animal"),
      _on_use_item = function(player, wielded_item, pointed_thing)
        local def = minetest.registered_items[wielded_item:get_name()]
        wielded_item:take_item()
        player:set_wielded_item(wielded_item)
        minetest.sound_play("animals_slaughter",{pos = player:get_pos(), gain = 0.5, pitch = (math.random(69,80)/100)})
        local inv = player:get_inventory()
        for _,item in ipairs(def.drops) do
          if inv:room_for_item("main", item) then
              inv:add_item("main", item)
            else
              minetest.add_item(minimal.shift_pos(player:get_pos(), { y=1 }),
              item)
              -- #TODO: Sound for drops
            end
          end
        end,
    on_place = function(itemstack, placer, pointed_thing)
      local spawn_pos = pointed_thing.above
      -- am I clicking on something with existing on_rightclick function?
      local def = minimal.get_nodedef(pointed_thing.under)
      if (def and def.drawtype ~= "liquid" and -- ignore liquids
      pointed_thing.type ~= nil) then -- prevent running on_rightclick function upon custom item drop
        local on_click = minimal.on_rightclick(itemstack, placer, pointed_thing)
        if on_click ~= false then
          return on_click
        end
      end
      if not minetest.registered_entities[name] then -- entity not registered, prevent rest of code execution
        return
      end
      if (self.class == 2 and def.drawtype == "liquid") then
        -- place fish properly into water
        spawn_pos = minimal.pos_shift(pointed_thing.under,{y = -1})
      end
      if spawn_pos and not minetest.is_protected(spawn_pos, placer:get_player_name()) then
        spawn_pos = pos_to_spawn(name, spawn_pos)
        local ent = create_mob(placer, itemstack, name, spawn_pos)
        --set energy value
        if not mobkit.recall(ent,'energy') then
           --# of seconds it will survive without food
           local energy = ee / animals.calculate_egg_young(ype)
           mobkit.remember(ent,'energy',energy)
        end
      end
      return itemstack
    end,
  }
   -- dropped animal egg spawns the animal
   function item_table.on_drop(itemstack, dropper, pos)
      -- craft a quick pointed_thing lol
      local pointed_thing = {}
      pointed_thing.above = minimal.shift_pos(pos,{y = 1}) --{x = pos.x, y = pos.y + 1, z = pos.z}
      pointed_thing.under = pos

      return item_table.on_place(itemstack, dropper, pointed_thing) -- run on_place function
   end
   minetest.register_craftitem(name, item_table) -- register egg
end


animals.capture = function(self, clicker)
	-- add special mob egg with all mob informationl
	local new_stack = ItemStack(self.name)
	local stack_meta = new_stack:get_meta()
	--local sett ="---TABLE---: "
	--local sett = ""
	--local i = 0
	for key, value in pairs(self) do
	   if key == "hp" then
	      stack_meta:set_string(key, value)
	   elseif key == "memory" then
	      stack_meta:set_string(key, minetest.serialize(value))
	   end
	end
	local idef = minetest.registered_items[self.name] or {}
	if idef._tool_tips and idef._tool_tips ~= '' then
	   stack_meta:set_string('description',
				 idef.description .. idef._tool_tips)
	end

	local inv = clicker:get_inventory()
	if inv:room_for_item("main", new_stack) then
		inv:add_item("main", new_stack)
		self.object:remove()
	else
		minimal.warn_inv_full(clicker)
	end

	return stack_meta
end
