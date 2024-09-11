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
    local def = type(name) == "table" and name or minetest.registered_entities[name]
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
animals.stun_catch_mob = function(self, clicker, time_from_last_click,
                                  tool_capabilities)--,chance,canhand)
    if not clicker or not minetest.is_player(clicker) then return end
    if self.hp <= 0 then return end
    local item = clicker:get_wielded_item()
    local item_name = item:get_name()
    tool_capabilities = type(tool_capabilities) == "table" and tool_capabilities
        or {full_punch_interval = 1}
    if not self.capture_interactions then
        return false,false -- creature can't be captured + is not captured
    end
    local success_rate
    for group,values in pairs(self.capture_interactions) do
        if (group == "hand" and (item_name == ""
                                 or tool_capabilities.is_hand) ) then
            success_rate = values[1]
            -- it's just a hand, why would there be more options than 1?
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
                    -- no possible way this tool will work
                    --  (item group is less than the provided necessary group)
                    break
                else
                    -- update success_rate
                    if not success_rate or -- define success_rate OR
                        (success_rate and perc > success_rate) then
                        -- choose what gives the best chances
                        success_rate = perc
                    end
                end
            end
        end
    end
    if not success_rate then
        return false,false
    end
    time_from_last_click = type(time_from_last_click) == "number"
        and time_from_last_click or 1
    -- modify success_rate according to tool_capabilities (if not in creative)
    -- 100% is 100%, you've whacked em good, no need to worry about last click!
    if success_rate < 1 and not minimal.player_in_creative(clicker) then
        success_rate = success_rate *
            math_clamp(time_from_last_click
                       / tool_capabilities.full_punch_interval, 0, 1)
    end
    if self.hp <= self.max_hp*0.75 then -- if less than 3 quarters of full HP
        -- then calculate damage-based capture success
        local damaged_multiplier = math_clamp(1/(self.hp/self.max_hp)
                                              * (self.damaged_capture_multiplier
                                                 or 1),1,math.huge )
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

-- animals.register_spawnegg, register_spawnegg
-- spawnegg registration, requires animal parameter
-- will create a young_per_egg and energy_egg (egg_energy) if not provided with one
-- if liquids_pointable isn't boolean, will set to true if the provided animal is aquatic (class == 2)
-- if inventory_image isn't provided, will seek for one using the animal's name, expecting a png
animals.register_spawnegg = function(name, def, animal)
  assert(type(def) == "table",
         "animals.register_spawnegg: provided spawnegg definition is not a table!")
  -- animal getting
  animal = type(animal) == "table" and animal or type(animal) == "string" and animal or name
  animal = type(animal) == "table" and animal or type(animal) == "string" and minetest.registered_entities[animal]
  assert(animal,
    "animals.register_spawnegg: was given an improper 'animal' definition (spawn_animal/3rd function paramter) for "..name..
    ". Could not find in registered_entities or was not given a string to index with or a definition table to use.")
  name = type(name) == "string" and name or animal.name
  assert(type(name) == "string",
         "animals.register_spawnegg: was not provided a string for name, got '"
         ..type(name).."'")

  -- custom definitions
  def.spawn_animal = animal
  def.egg_energy = def.egg_energy or animal.energy_egg or 100
  def.young_per_egg = def.young_per_egg or animal.young_per_egg or 1
  def._use_tip = def._use_tip or S("Slaughter the animal")

  -- groups
  def.groups = def.groups or {}
  def.groups.spawn_egg = 1

  -- definitions
  def.description = def.description or
      (animal._desc and S("Live @1",animal._desc)) or name
  -- get inventory_image or convert name into an image string expecting png
  def.inventory_image = def.inventory_image or name:gsub(":","_").."_item.png"
  def.stack_max = def.stack_max or minimal.stack_max_medium
  if animal.class == 2 and type(def.liquids_pointable) ~= "boolean" then
    def.liquids_pointable = true
  end
  def.liquids_pointable = type(def.liquids_pointable) == "boolean" and def.liquids_pointable or false
  def.drops = def.drops or animal.drops or nil

  -- sounds (#TODO: sound for drops)
  def.sounds = def.sounds or {}
  def.sounds.slaughter = def.sounds.slaughter or {
      name = "animals_slaughter",
      gain = 0.5,
      pitch = {0.69,0.80}
  }

  -- functions
  def.on_place = def.on_place or function(itemstack, placer, pointed_thing)
      local itemdef = itemstack and itemstack:get_definition()
      local s_animal = itemdef and itemdef.spawn_animal -- spawn animal
      if not s_animal then return end -- no spawn animal
      local spawn_pos = pointed_thing.above
      -- am I clicking on something with an existing on_rightclick function?
      local nodedef = minimal.get_nodedef(pointed_thing.under)
      if (nodedef and itemdef.drawtype ~= "liquid" and -- ignore liquids
          pointed_thing.type ~= nil) then
          -- prevent running on_rightclick function upon custom item drop
          local on_click = minimal.on_rightclick(itemstack, placer, pointed_thing)
          if on_click ~= false then
              return on_click
          end
      end
      
      if not itemdef.spawn_animal then
          -- entity not registered, prevent rest of code execution
          return
      end
      if (itemdef.liquids_pointable and itemdef.drawtype == "liquid") then
          -- place fish properly into water
          spawn_pos = minimal.pos_shift(pointed_thing.under,{y = -1})
      end
      if spawn_pos
          and not minetest.is_protected(spawn_pos,
                                        placer:get_player_name()) then
          spawn_pos = pos_to_spawn(s_animal, spawn_pos)
          local ent = create_mob(placer, itemstack, s_animal.name, spawn_pos)
          --set energy value
          if not mobkit.recall(ent,'energy') then
              --# of seconds it will survive without food
              local energy = itemdef.egg_energy / animals.calculate_egg_young(itemdef.young_per_egg)
              mobkit.remember(ent,'energy',energy)
          end
      end
      return itemstack
  end

  def.on_drop = def.on_drop or function(itemstack, dropper, pos)
      -- craft a quick pointed_thing lol
      local pointed_thing = {}
      pointed_thing.above = minimal.shift_pos(pos,{y = 1})
      pointed_thing.under = pos

      -- run on_place function (if it exists, should!!!)
      return type(def.on_place) == "function" and def.on_place(itemstack, dropper, pointed_thing) or nil
  end

  -- custom functions
  -- slaughtering mechanics
  def._on_use_item = def._on_use_item or function(player, wielded_item, pointed_thing)
      if type(player) ~= "userdata" and type(player) ~= "table" then return end
      local itemdef = wielded_item and wielded_item.get_definition and wielded_item:get_definition()
      if not itemdef then return end
      -- get and play slaughter sound
      local sound = itemdef.sounds.slaughter
      if sound then
          sound = table.copy(sound)
          sound.pos = player:get_pos()
          minimal.sound_play(sound)
      end
      -- convert to drops
      local inv = player.get_inventory and player:get_inventory()
      for _,item in pairs(itemdef.drops) do
          if inv and inv:room_for_item("main", item) then
              inv:add_item("main", item)
          -- no inventory or no room in inventory
          else
              minetest.add_item(minimal.shift_pos(player:get_pos(), {y=1}), item)
              sound = itemdef.sounds.slaughter_drop
              if sound then
                sound = table.copy(sound)
                sound.pos = player:get_pos()
                minimal.sound_play(sound)
              end
          end
      end
      wielded_item:take_item()
      player:set_wielded_item(wielded_item)
      return wielded_item
  end
  -- register spawnegg and return definition
  minetest.register_craftitem(name, def)
  return minetest.registered_items[name]
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
