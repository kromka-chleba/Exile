--
-- Register Egg
--for capturing and respawing unique animals
--

animals = animals
mobkit = mobkit

local S = animals.S

local pi = math.pi


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
    ent.hp = tonumber(meta:get_string("hp")) or ent.hp
    if memory then
        for key,value in pairs(memory) do
            mobkit.remember(ent,key,value)
        end
    end
    -- if player isn't in creative
    if not (minimal.player_in_creative(placer)) then
        itemstack:take_item() -- since mob is unique we remove egg once spawned
    end
    -- make sure young animals do not start with properties of fully grown ones
    if animals.init_size_modifications then -- should be true at runtime
        animals.init_size_modifications(ent)
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


-- animal recovered from being stunned -> get up
function animals.stunned_recovered(self)
    -- approach upright orientation from current rot in 6 steps
    local step = 0
    local rot = self.object:get_rotation()
    local init = true
    local get_up=function()
        if init then
            -- attention! regaining conciousness
            local vel = self.object:get_velocity()
            self.object:set_velocity(mobkit.pos_shift(vel,{y=0.5}))
            init = false
        end
        -- get up fast
        step = step + 1
        local xrot = rot.x * (1 - 0.1667 * step) -- -> 0
        local zrot = rot.z * (1 - 0.1667 * step) -- -> 0
        self.object:set_rotation({x = xrot, y = rot.y, z = zrot})

        if step > 5 then
            return true
        end
    end
    -- set high priority, to prevent the brain from making other decisions
    mobkit.queue_high(self, get_up, 97)
end

-- recoverering from being stunned
function animals.hq_stunned_recover(self, phi)
    local function recover()
        if self.hp / self.max_hp >= self.stunned.recover_at_hp
            and core.get_gametime() > self.stunned.recover_after then

            -- need to restore collisionbox?
            if self.stunned.collisionbox2 then
                local props = self.object:get_properties() or nil
                props = table.copy(props)
                props.collisionbox[2] = self.stunned.collisionbox2
                self.object:set_properties(props)
            end
            -- no more stunned
            self.stunned = nil
            -- get up!
            if self.animation and self.animation.unstunned then
                mobkit.animate(self,'unstunned')
            end
            animals.stunned_recovered(self)
            return true
        end

        if self.stunned.in_liquid then
            -- sway sideways, as if drifting in the waves
            phi = phi + 0.025 * pi -- 0.025: slower than with initial fall
            local strength = 0.2 -- weaker than initially
            local zrot = strength * math.sin(phi) -- initially to the right
            local rot = self.object:get_rotation()
            self.object:set_rotation({x = rot.x, y = rot.y, z = zrot})
         end
    end
    -- set high priority, to prevent the brain from making other decisions
    mobkit.queue_high(self, recover, 98)
end

-- loose conciousness and fall or do whatever fits for a certain species
function animals.hq_stunned_fall(self)
    local phi = 0 -- parameter to control progress
    local init = true
    local fall = function()
        if init then
            -- idle until hp reaches 40 - 60% of max_hp, but at least 20% over
            -- current hp (randomize, so it is not too easy to guess when it
            -- happens)
            local range = 0.4 + 0.2 * math.random() -- 40 - 60%
            local req_hp = math.max(range, self.hp / self.max_hp + 0.2)
            -- anyways -> recovery finished at full hp
            req_hp = math.min(req_hp, 1)
            self.stunned = {
                recover_at_hp = req_hp,
                -- recovery should not end until some time has elapsed
                recover_after = core.get_gametime() + math.random(4, 11),
                in_liquid = self.isinliquid
            }
            if not self.isinliquid then
                -- shorten collisionbox on lower end to let it collapse, a bit
                local props = self.object:get_properties() or nil
                props = table.copy(props)
                local box = props.collisionbox
                self.stunned.collisionbox2 = box[2] -- to be restored

                box[2] = box[2] + (box[5] - box[2]) * 0.2
                self.object:set_properties(props)
            end
            -- switch animation
            if self.animation and self.animation.stunned then
                mobkit.animate(self,'stunned')
            else
                mobkit.animate(self,'dead')
            end
            init = false
        end

        phi = phi + 0.05 * pi -- 0.05 defines speed of effect and duration

        -- generic animation based on rotation and translation
        if self.isinliquid then
             -- sway sideways, stronger for class 2 as if drifting in the waves
             local strength = 0.4
             local zrot = strength * math.sin(phi) -- initially to the right
             local rot = self.object:get_rotation()
             self.object:set_rotation({x = rot.x, y = rot.y, z = zrot})
        end

        if phi >= 2 * pi then
            animals.hq_stunned_recover(self, phi)
            return true
        end
    end

    -- stunned - cannot decide to do anything else -> set high priotity, to
    -- prevent the brain from making other decisions
    -- NOTE mobkit.clear_queue_high() as in animals.die() would still remove
    --      stunning behaviour, but other functions have to first check whether
    --      an animal is stunned (better approach: Integrate stunned state
    --      into mobkit's queue mechanisms, also as a condition before calling
    --      animal's logic function!  But then, most of animals.core_hp() and
    --      animals.core_life() have to be moved from the brain functions to
    --      an animals.physics() function that would run independent of being
    --      stunned. However, currently core_life() may also change behaviour,
    --      which actually belongs to the logic() rather than to physics().)
    mobkit.queue_high(self, fall, 99)
end

-- chance of being stuned: selects basic chance from capture_interactions
-- `item_name`: name of wielded item
-- `any_item_stuns`: if true, any item gives at least the chance as the hand
-- 3 cases to handle:
-- - weapon that stuns, e.g. stone club,
-- - hand item "",
-- - any_item_stuns == true
-- returns change and group to apply or nil,
--    NOTE here for club vs. Gundu the order of club and hand values in
--    the Gundu's capture_interactions matters!
function animals.get_stun_power(self, item_name, any_item_stuns)
    -- can the animal be stunned
    if not self.capture_interactions then
        return -- (nil, nil) creature can't be stunned + no possible group
    end

    local chance -- chance of being stunned if any, otherwise nil
    local group -- stunning group to apply, or nil if no group matches
    for ci_group, values in pairs(self.capture_interactions) do
        local wields_hand = (core.get_item_group(item_name, "hand") > 0)
        if ci_group == "hand" and (wields_hand or any_item_stuns) then
            -- update chance
            if not chance or -- initialize chance OR
                (chance and values[1] > chance) then
                -- support only hand = 1 for tool groups
                -- no Old Shatterhand's version :)
                chance = values[1]
                group = "hand"
            end
            -- the hand has only then "hand" group -> finished
            if item_name == "" then break end
        end
        -- check for other stunning groups
        local itemg = core.get_item_group(item_name, ci_group) -- item group
        if itemg ~= 0 then
            -- iterate over table to apply highest defined percentage for itemg
            -- NOTE external mods may use more than one percentage, Exile's
            --      built-in animals do not and built-in tools have itemg = 1
            for level, perc in pairs(values) do
                if level > itemg then
                     break -- cannot find another match in this loop
                else
                    -- update chance
                    if not chance or -- define chance OR
                        (chance and perc > chance) then
                        -- choose what gives the best chances
                        chance = perc
                        group = ci_group
                    end
                end
            end
        end
    end
    return chance, group
end

-- apply stunning effects
-- `clicker` must be a player, `time_from_last_click` a float > 0.0,
-- `damage` will be split into a modifier for the success rate of bein stunned
-- and physical damage, `tool_capabilities`: same as with on_punch(),
-- `all_items_stun`: override to apply stunning with every item
-- returns: modified damage (or unmodified if no capability to stun)
animals.try_stun_mob = function(self, clicker, time_from_last_click, damage,
                                tool_capabilities, all_items_stun)
    -- safety checks
    if not clicker or not core.is_player(clicker) then
        return damage -- damage unmodified
    end
    if self.about_to_go then return damage end -- damage unmodified
    local tool_caps = tool_capabilities or {} -- safety

    -- 1st - deternime basic success rate (sr) based on tool or item vs. animal
    --       + which group applies ("hand" "club", ...
    local wielded_item = clicker:get_wielded_item()
    local item_name = wielded_item:get_name()
    local sr, igroup = animals.get_stun_power(self, item_name, all_items_stun)

    if not sr then return damage end -- damage unmodified
    -- -> stunning possible, implies igroup ~= nil

    -- 2nd - for clubs: split damage into actual damage and a multiplier for sr
    local item_multiplier = 0
    if igroup == "club" and damage <= 1 then -- safety
        igroup = "hand"
        damage = 1
    end
    if igroup == "club" then
        -- apply damage in the range damage/2 to damage
        -- (does not work with damage==1!)
        local rnd = math.random()
        damage = math_clamp(math.floor(0.5 * damage * (1 + rnd) + 0.5),
                            0, damage)
        -- e.g. damage==8 (stone club), an even number:
        -- possible damage and chances: 4 (1:8), 5 (2:8), 6 (2:8), 7 (2:8),
        --                              8 (1:8)
        -- odd numbers: e.g. damage==5: 3 (2:5), 4 (2:5), 5 (1:5)
        item_multiplier = 0.5 + rnd  -- range: [0.5,1.5)

        -- strong weapon against few hit points?
        -- -> less likely to survive the hit, ending up stunned
        if damage > self.hp then
            item_multiplier = item_multiplier * self.hp/damage
            -- e.g. iron mace vs. baby Sneachan, hp = 1:
            --    [0.5,1.5), * 1/12 -> [0.042,0.125)
        end
    elseif igroup == "hand" then
        if damage == 1 then --
            if math.random() > 0.5 then -- 50:50
                item_multiplier = 1
                damage = 0
            -- else: no changes -> no stunning
            end
        else -- custom strong hand? not the case with Exile's hands
            item_multiplier = 1
            damage = damage - 1
        end
    end
    -- no splitting for other 'capture groups' (e.g. 'net')

    sr = sr * item_multiplier

    -- 3rd - modify sr according to full_punch_interval.
    -- With a sr of 1 - from above - an animal gets caught on first
    -- attempt. Then time_from_last_click would have no effect here.
    if sr < 1 then
        time_from_last_click = type(time_from_last_click) == "number"
            and time_from_last_click or 1

        local fpi = tool_caps.full_punch_interval or 1.0
        sr = sr * math_clamp(time_from_last_click / fpi, 0, 1)
    end

    -- 4th - modify success_rate based on damage or on max_hp/hp respectively
    if self.hp <= self.max_hp * 0.75 then -- if less than 3 quarters of full HP
        -- NOTE damaged_capture_multiplier (dcm) is for modding support
        local damaged_multiplier = math_clamp(1 / (self.hp / self.max_hp)
                                    * (self.damaged_capture_multiplier or 1),
                                                                1, math.huge)
        -- max_hp/hp: e.g. 50% (or 10%) hp left -> multiplier = 2 x dcm (10x),
        -- For animals with max_hp == 3 1x (1.5x or 3x) dcm is possible.
        -- For an animal with 5 of 200 hp left, it will be 40 x dcm!
        -- damaged_multiplier as function of hp and dcm:
        -- hp (%)         : 100 | 76 | 75   | 50   | 20   | 10   | 5
        -- dcm == 0.5     :  1  | 1  | 1    | 1    | 2.5  | 5.0  | 10
        -- dcm == nil or 1:  1  | 1  | 1.33 | 2.0  | 5.0  | 10.0 | 20
        -- dcm == 2       :  1  | 1  | 2.66 | 4.0  | 10.0 | 20.0 | 40
        -- dcm == 5       :  1  | 1  | 6.66 | 10.0 | 25.0 | 50.0 | 100
        sr = sr * damaged_multiplier
    end

    -- exception for creative -> 100%, why not? Use other weapons to kill!
    if minimal.player_in_creative(clicker) then
        sr = 1
        damage = 0
    end

    -- 5th - stun or not?
    if sr >= math.random() then
        -- bad luck - successfully stunned by clicker
        animals.make_sound(self,'caught','punch')

        -- stunned! -> forget what you're doing
        mobkit.clear_queue_high(self)
        mobkit.clear_queue_low(self)
        self.stunned = {}
        animals.hq_stunned_fall(self)
    end

    return damage
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
    "animals.register_spawnegg: was given an improper 'animal' definition (3rd function paramter) for "..name..
    ". Was not given a definition table or could not find provided string in registered_entities.")
  name = type(name) == "string" and name or animal.name
  assert(type(name) == "string",
         "animals.register_spawnegg: was not provided a string for name, got '"
         ..type(name).."'")
  -- fix name properly (we use it to find textures sometimes)
  name = name:sub(1,1) == ":" and minetest.get_current_modname()..name or
      not name:match(":") and minetest.get_current_modname()..":"..name or name

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
  def.drops = def.drops or animal.drops or {}

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
      -- don't run rightclick function if sneaking
      if (minetest.is_player(placer) and not placer:get_player_control().sneak) and
      (nodedef and nodedef.drawtype ~= "liquid" and -- ignore liquids
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
      if not minetest.is_player(player) then return end
      local itemdef = wielded_item:get_definition()
      if not itemdef then return end
      -- get and play slaughter sound
      if itemdef.sounds.slaughter then
          minimal.sound_play(player:get_pos(), itemdef.sounds.slaughter)
      end
      -- convert to drops
      local inv = player.get_inventory and player:get_inventory()
      for _,item in pairs(itemdef.drops) do
          if inv and inv:room_for_item("main", item) then
              inv:add_item("main", item)
          -- no inventory or no room in inventory
          else
              minetest.add_item(minimal.shift_pos(player:get_pos(), {y=1}), item)
              if itemdef.sounds.slaughter_drop then
                  minimal.sound_play(player:get_pos(), itemdef.sounds.slaughter_drop)
              end
          end
      end
      wielded_item:take_item()
      return wielded_item
  end
  -- register spawnegg and return definition
  minetest.register_craftitem(name, def)
  return minetest.registered_items[name]
end


animals.capture = function(self, clicker)
    -- add special mob egg with all mob information
    local new_stack = ItemStack(self.name)
    local stack_meta = new_stack:get_meta()
    if self.hp then
        stack_meta:set_string("hp", self.hp)
    end
    if self.memory then
        stack_meta:set_string("memory", minetest.serialize(self.memory))
    end

    local inv = clicker:get_inventory()
    if inv:room_for_item("main", new_stack) then
        inv:add_item("main", new_stack)
        -- fix for pegasun scared sound playing globally (delete object on delay)
        self.about_to_go = true  -- no duplicate capture during delay
        minetest.after(0.05,function()
            self.object:remove()
        end)
    else
        minimal.warn_inv_full(clicker)
    end

    return stack_meta
end
