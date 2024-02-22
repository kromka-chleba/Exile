--
-- Register Egg
--for capturing and respawing unique animals
--

animals = animals
mobkit = mobkit

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
animals.stun_catch_mob = function(self, clicker,chance,canhand)
	if self.hp <= 0 then return end
	local item = clicker:get_wielded_item()
	local item_name = item:get_name()
	item = minetest.get_item_group(item_name,"club")

	if (item ~=0 or (canhand == true and item_name == "")) then
		--hit
		mobkit.make_sound(self,'punch')
		--catch chance
		if math.random() < chance then
			mobkit.make_sound(self,'punch')
			animals.capture(self, clicker)
		end
	end
end





animals.register_egg = function(self, desc, inv_img, stack)
   local grp = {spawn_egg = 1}
   local name = self.name
   assert(type(name) == "string","animals.register_egg: provided self data does not contain a name!")
   local ee = self.energy_egg or 100
   local ype = self.young_per_egg or 1
   local dr = self.drops
   local liquids_pointable = false
   if (self.class == 2) then
      liquids_pointable = true
   end
   local item_table = { -- register new spawn egg containing mob information
      description = desc,
      inventory_image = inv_img,
      --groups = {},
      stack_max = stack,
      groups = grp,
      drops = dr,
      liquids_pointable = liquids_pointable,
      _use_tip = "Slaughter the animal",
      _on_use_item = function(player, wielded_item, pointed_thing)
	 local def = minetest.registered_items[wielded_item:get_name()]
	 wielded_item:take_item()
	 player:set_wielded_item(wielded_item)
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
	 local under = pointed_thing.under
	 local def = minimal.get_nodedef(under)
	 if (def and def.on_rightclick and def.drawtype ~= "liquid" -- as long as it's not a liquid lol
	     and pointed_thing.type ~= nil) then-- and also prevent it from running on_rightclick function upon item drop

	    return minimal.on_rightclick(itemstack, placer, pointed_thing)
	 end
	 if (self.class == 2 and def.drawtype == "liquid") then
	    -- place fish properly into water
	    spawn_pos = minimal.pos_shift(under,{y = -1})
	 end
	 if spawn_pos and not minetest.is_protected(spawn_pos, placer:get_player_name()) then
	    if not minetest.registered_entities[name] then
	       return
	    end
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
   -- add special mob egg with all mob information
   local new_stack = ItemStack(self.name)
   local stack_meta = new_stack:get_meta()
   --local sett ="---TABLE---: "
   --local sett = ""
   --local i = 0
   for key, value in pairs(self) do
      local what_type = type(value)
      if what_type ~= "function"
	 and what_type ~= "nil"
	 and what_type ~= "userdata"
      then
	 if what_type == "boolean" or what_type == "number" then
	    value = tostring(value)
	 end
	 if key == 'memory' then
	    value = minetest.serialize(value)
	 end
	 stack_meta:set_string(key, value)
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
