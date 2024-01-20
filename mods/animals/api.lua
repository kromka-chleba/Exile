local random = math.random
local pi = math.pi
local time = os.time
local sqrt = math.sqrt

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min
local tan = math.tan
local pow = math.pow

local function math_clamp(...) -- num, min, max
  return minimal.math_clamp(...)
end

local max_objects = 30
local mo_check_radius = 40 -- maxobject check radius

animals = animals
mobkit = mobkit

local use_vh1 = minetest.get_modpath("visual_harm_1ndicators")

-- table to emulate time_from_last_punch for rightclick
animals.rclick_times = {}

--------------------------------------------------------------------------
--basic
--------------------------------------------------------------------------


-- returns 2D angle from self to target in radians
local function get_yaw_to_object(pos, opos)
  local ankat = pos.x - opos.x
  local gegkat = pos.z - opos.z
  local yaw = math.atan2(ankat, gegkat)
  return yaw
end

-- 1 function to get time from (allows for ease of modification)
-- allows optional "since" value, expected number, returns it subtracted by got time
local function get_time(since)
  local c_time = minetest.get_server_uptime() -- current_time
  if (type(since) == "number") then
    return (c_time - since)
  end
  return c_time
end


--flee sound (has to be in water!)
local function flee_sound(self)
	if not self.isinliquid then
		return
	end
	mobkit.make_sound(self,'flee')
end

-- return the luaentity and object of a provided userdata if possible into a table
function animals.get_structure(obj)
  local obj_t = {} -- obj_table
  if (type(obj) == "userdata" and obj["get_luaentity"]) then
    -- get luaentity table and its object
    obj_t.ent = obj:get_luaentity()
    obj_t.object = obj_t.ent.object
    return obj_t
  end
  if (type(obj) == "table" and type(obj.object) == "userdata") then
    -- get "luaentity" (hopefully) and its object
    obj_t.ent = obj
    obj_t.object = obj_t.ent.object
    return obj_t
  end
  return nil
end

-- ask if the temperature is comfy for the lil creature
function animals.temp_comfy(self,temp)
  if (type(self) ~= "table" and type(self) ~= "userdata") then
    return false
  end
  if (type(temp) ~= "number") then
    local pos = mobkit.get_stand_pos(self)
    if (type(temp) == "table") then
      if (temp.x and temp.y and temp.z) then
        pos = temp
      end
    end
    temp = climate.get_point_temp(pos, true)
  end
  
  -- still not a number somehow
  if (type(temp) ~= "number") then
    return false
  end
  local min_temp = self.min_temp or 0
  local max_temp = self.max_temp or 20
  
  if (temp >= min_temp and temp <= max_temp) then
    -- goldilocks certified
    return true
  -- return whether too hot or too cold for possible analysis
  elseif (temp < min_temp) then
    return false,"cold"
  elseif (temp > max_temp) then
    return false,"hot"
  end
  return false
end

--------------------------------------------------------------------------
-- node interactions
--------------------------------------------------------------------------

local function node_drawtype(pos)
  if not (type(pos) == "table") then
    return {}
  end
  local node = pos
  if (pos.x and pos.y and pos.z) then
    -- if pos is a pos, otherwise continue as is
    node = minetest.get_node_or_nil(pos)
  end
  if (type(node) == "nil" or type(node.name) ~= "string") then
    node = {}
  else
    node = minetest.registered_nodes[node.name]
  end
  if not node then return "normal", {} end -- assume it's a solid ignore node?
  return node.drawtype, node
end

-- get a randomized position from mobkit's is_neighbor_node_reachable by sending a string that's 1 to 8 or like so:
-- "12345678"
-- the mobkit function only accepts numbers from 1 to 8, as it uses them to index a table
-- returns the numstring
local function get_reachable_node(self,numstring)
  if (type(numstring) == "number") then
    numstring = tostring(numstring)
  end
  if (type(numstring) ~= "string") then
    -- create one :D
    numstring = "12345678"
  end
  if (type(self) ~= "table" and type(self) ~= "userdata") then
    return nil
  end
  -- get a random number from 1 to length of numstring and then remove it from numstring
  -- gets a number for a position index in mobkit's reachable_node
  local length = string.len(numstring)
  
  local num = random(1,length)
  num = tonumber(string.sub(numstring,num,num)) -- got number
  numstring = string.gsub(numstring,tostring(num),"") -- erase number from numberstring
  
  return numstring,mobkit.is_neighbor_node_reachable(self,num)
end

--------------------------------------------------------------------------
-- external mod support
--------------------------------------------------------------------------

-- optional "clear" boolean to force a clear anyways
function animals.vh_bar(self,clear)
  if not use_vh1 then
    return
  end
  if (self and mobkit.is_alive(self)) and not clear  then
    VH1.update_bar(self.object, self.hp, self.max_hp)
  elseif self and self.object then
    VH1.clear_bar(self.object)
  end
end

--------------------------------------------------------------------------
--Health
--------------------------------------------------------------------------

function animals.modify_hp(self,hp)
  if not (type(hp) == "number") then
    return
  end
  hp = math.ceil(hp) -- no decimals
  self.hp = self.hp + hp
  animals.vh_bar(self)
end

--------------------------------------------------------------------------
-- Sounds
--------------------------------------------------------------------------

function animals.get_egg_sounds()
  return nodes_nature.node_sound_defaults({
    hatch = {
      name = "animals_hatch_egg",
      gain = 0.8,
      max_hear_distance = 8
    }
  })
end

--------------------------------------------------------------------------
--Life and death
--------------------------------------------------------------------------

----------------------------------------------------
-- drop on death what is defined in the entity table
function animals.handle_drops(self)
   animals.vh_bar(self,true)

   if not self.drops then
     return
   end

   for _,item in ipairs(self.drops) do

     local amount = random (item.min, item.max)
     local chance = random(1,100)
     local pos = self.object:get_pos()

     if chance < (100/item.chance) then
       --leave time for death animation to end
       minetest.after(2.8, function()
         if (type(self.object) == "userdata") then -- if entity then
           pos = self.object:get_pos() or pos -- get entity's pos or if pos is nil, use old pos
         end
	 pos.y = pos.y+0.5
         item = item.name  -- convert into string to avoid conflicts (and override)
        -- if the animal was burned to death
        if (self.burnt == true) then
          -- look for possible "burn" versions of the item to be dropped
          local possitem = item.."_burned"
          if (minetest.registered_items[possitem]) then
            item = ItemStack(possitem):get_name()
          end
          possitem = item.."_burnt"
          if (minetest.registered_items[possitem]) then
            item = ItemStack(possitem):get_name()
          end
        end
         minetest.add_item(pos, item.." "..tostring(amount))
       end)
     end

   end
 end

----------------------------------------------------
--core health (meant for instantanious effect checks)
function animals.core_hp(self)
  -- vitals: fall damage
	local vel = self.object:get_velocity()
	local velocity_delta = abs(self.lastvelocity.y - vel.y)

  if (velocity_delta > mobkit.safe_velocity) then
    -- let's see if there's a node with fall_damage_add_percent first
    local pos = mobkit.pos_shift(self.object:get_pos(),{y = -1})
    local drawtype, node = node_drawtype(pos)
    if (drawtype == "airlike") then
      pos = mobkit.pos_shift(pos,{y = -1})
      drawtype, node = node_drawtype(pos)
    end
    
    if (node.name ~= nil) then
      local multiplier = node.groups.fall_damage_add_percent -- used for fall damage calculation
      if (type(multiplier) == "number") then
        -- convert multiplier into a usable decimal
        multiplier = multiplier/100
        if (multiplier <= 0) then
          -- if it's negative, make positive, and subtract it by 1 to get the result of which velocity should be of itself (-70 = 0.3)
          multiplier = -multiplier
          multiplier = 1 - multiplier
        else
          multiplier = 1 + multiplier
        end
        
        velocity_delta = floor(velocity_delta * multiplier)
      end
      
      if (drawtype == "airlike") then
        multiplier = 0 -- lazily reuse multiplier to check whether or not it's hitting entity or air
        local obj = minetest.get_objects_inside_radius(pos,1) -- look for an object nearby
        obj = obj[random(1,#obj)] -- lazily get one of em
        if obj then
          obj = obj:get_luaentity()
          if obj and obj.physical == true and obj.collide_with_objects == true then
            -- landed on someone, cushion it
            multiplier = 0.5
          end
        end
        velocity_delta = velocity_delta * multiplier
      end
    end
  end

  if velocity_delta > mobkit.safe_velocity then
     -- alright, time to do some damage if it's still over safe_velocity
     local damage = floor(self.max_hp * min(1, velocity_delta/mobkit.terminal_velocity))

     animals.modify_hp(self,-damage)
  end
end



local function get_mean_temp(pos) -- this could be put somewhere else like in climate or minimal
  local temps = {}

  if (type(pos) ~= "table") then -- no pos table is given then
    return 15
  elseif (type(pos.x) ~= "number" or type(pos.y) ~= "number"
	  or type(pos.z) ~= "number") then -- incase an invalid pos is given
     return 15
  end

  for x = -1, 1, 1 do -- create matrix of possible positions
    for y = -1, 1, 1 do
      for z = -1, 1, 1 do
        local npos = {x = (pos.x - x), y = (pos.y - y), z = (pos.z - z)} -- matrix the pos :D

        temps[#temps + 1] = climate.get_point_temp(npos, true)
      end
    end
  end

  local mtemp = 0 -- start with a number so it can be calculated
  for _,num in pairs(temps) do
    mtemp = mtemp + num
  end

  return mtemp / #temps -- return the "mean" of the matrix'd temps
end

----------------------------------------------------
--core health, energy and age
function animals.core_life(self, pos)

  local energy = mobkit.recall(self,'energy')
  local age = mobkit.recall(self,'age')
  local conserve = mobkit.recall(self,'conserve')

  local lifespan = self.lifespan or 2
  local energy_loss = self.energy_loss or 0.25

  --stops some crashes in creative?
  if not energy then
    energy = 1
  end
  if not age then
    age = 0
  end
  if not conserve then
    conserve = false
  end

  age = age + 1

  animals.vitals(self)
  --die from exhaustion, old age, no hp
  local hp = self.hp
  if energy <= 0 or age > lifespan or self.hp <= 0 then
    if type(self._on_death) == "function" then
      self._on_death(self, pos)
    end
    mobkit.clear_queue_high(self)
    animals.handle_drops(self)
    mobkit.hq_die(self)
    return nil
  end

  if (conserve == false) then
    energy = energy - energy_loss
  elseif (random() <= 0.005) then -- 0.5% chance to lose energy during energy conservation
    energy = energy - energy_loss
  end

  -- get temp
  local temp = climate.get_point_temp(pos, true)
  if (temp == 450) then -- get the mathematical "mean" of the pos and the surroundings nodes (workaround to torches)
    temp = get_mean_temp(pos)
  end

  --temperature stress
  local max_temp = self.max_temp
  local min_temp = self.min_temp

  if temp < min_temp or temp > max_temp then
    -- if this temperature is uncomfortable, try to find somewhere else!
    local killer_min_temp = min_temp - 7
    local killer_max_temp = max_temp + 25
    local burn_max_temp = killer_max_temp + 55
    local absolute_death_temp = burn_max_temp + 500
    
    if (self.class ~= 2) then
      -- only for land creatures
      if (temp > killer_max_temp or temp < killer_min_temp) then
      -- clear all queues, you gotta get outta here! We dyin!
        mobkit.clear_queue_low(self)
        mobkit.clear_queue_high(self)
        animals.hq_roam_comfort_temp(self,65)
      else
        -- not as critical (uncomfortable, but not dying)
        animals.hq_roam_comfort_temp(self,42)
      end
      
      conserve = false -- moving around, thus not conserving energy
    end
    -- lose energy from discomfort
    energy = energy - 2
    -- lose more energy dependent on temperature difference (discomfort also)
    if (temp > max_temp) then
      local mtp = (temp - max_temp)*0.05
      energy = energy - mtp
    elseif (temp < min_temp) then
      local mtp = (min_temp - temp)*0.02
      energy = energy - mtp
    end
    
  -- get really hurt or die from high temp
    if temp > killer_max_temp then -- use addition instead of multiplication to account for negative numbers
      local mtp = (temp - killer_max_temp)*0.01 -- multiplier
      local dmg = math.ceil(1 * mtp) -- damage calculation
      if (temp >= absolute_death_temp) then
        dmg = dmg * 16
      end
      dmg = math_clamp(dmg,1,self.hp) -- clamp dmg
      animals.modify_hp(self,-dmg)
      -- only retrieve burned flesh if max_temp is exceedingly hot
      if (self.hp <= 0 and temp >= burn_max_temp) then
        -- if animal successfully burned to death then
        energy = 0
        self.burnt = true
      end
    -- get really hurt or die from being too cold!!
    elseif temp < killer_min_temp then
      local mtp = (killer_min_temp - temp)*0.4 -- multiplier
      local dmg = math.ceil(1 * mtp)
      dmg = math_clamp(dmg,1,self.hp)
      animals.modify_hp(self,-dmg)
    end
  end


  --heal using energy
  -- if needs healing
  if (self.hp < self.max_hp and random() <= 0.75 and get_time(self.last_punched) >= 6) then
    -- if not a fish out of water then (fish in water will heal up nicely :D) (oh and if temp is comfortable too)
    if animals.temp_comfy(self,temp) and not (not self.isinliquid and self.class == 2) then
      -- calculate cost
      local cost = math.random(5,10)
      cost = cost * (1 + (self.max_hp/self.hp) ) -- increase cost depending on how harmed the creature is
      -- calculate w/ health efficiency
      local h_eff = self.heal_efficiency or 1
      cost = cost - (cost/20 * h_eff) -- cost subtracted by itself divided by 20 times heal_efficiency
      -- stabilize cost
      cost = math.round(cost*10)/10 -- round second decimal point (7.52 --> 7.5)
      if cost < 0 then cost = 0 end -- do not go below 0
      if energy > cost*1.1 then
        -- could heal (likelihood determined by how much energy the creature has over the cost)
        if (random() >= cost/energy) then
          animals.modify_hp(self,1)
          energy = energy - cost
        end
      end
    end
  elseif (self.hp > self.max_hp) then
    -- this aint supposed to happen!
    self:set_hp(self.max_hp)
  end

  if (conserve == true) then
    mobkit.clear_queue_low(self)
    mobkit.animate(self,"dead")
  end

  return age, energy, conserve
end



----------------------------------------------------
--put an egg in the world, return energy
function animals.place_egg(self, pos, e, medium) -- self, position, energy, medium
  -- uses self's energy and energy_egg (with optional max_pop)
  if (medium == nil or medium == "") then
    medium = "air"
  end
  local p = mobkit.get_node_pos(pos)
  local e_egg = self.energy_egg
  local egg_name = self.egg_name or self.name.."_eggs"
  -- seek a "self.egg_name" or create an egg_name using the placer's name
  local max_pop = self.max_pop or max_objects
  
  -- remove male or baby identifier when checking names
  local check_name = string.gsub(self.name,"_male","")
  check_name = string.gsub(self.name,"_baby","")
  
  local objcount = #animals.get_entities_inside_radius(check_name,pos,mo_check_radius)

  if minetest.get_node(p).name == medium and objcount <= max_pop then

    local posu = {x = p.x, y = p.y - 1, z = p.z}
    local n = mobkit.nodeatpos(posu)

    if n and n.walkable and n.name ~= "nodes_nature:tree_mark" then
      minetest.set_node(p, {name = egg_name})
      e = e - e_egg
    end

  end

  return e
end

-- place an egg during near or precise death (and die)
-- generic function to be utilized by any "emergency_egg" custom function in animals' self
function animals.emergency_egg(self, pos, medium)
  local egg_chance = self.emergency_egg_chance or 1
  
  local energy = mobkit.recall(self,"energy")
  if (type(energy) ~= "number" or energy <= 0) then
    return false
  end
  
  if (random() < egg_chance) then
    -- lay egg
    animals.place_egg(self, pos, energy, medium)
    -- set custom energy_egg
    local meta = minetest.get_meta(pos)
    meta:set_float("energy_egg",energy)
    
    mobkit.remember(self,"energy",0) -- kill
    return true
  end
  
  return false
end

----------------------------------------------------
-- get an amount of offspring to release
function animals.calculate_egg_young(self)
  local young_per_egg = self -- in case you just want to pass the young_per_egg instead
  if (type(self) == "table" or type(self) == "userdata") then
    if (self.young_per_egg) then
      young_per_egg = self.young_per_egg
    end
  end
  
  if (type(young_per_egg) == "table") then
    -- allow for randomized amount of young per egg
    if (type(young_per_egg[1]) == "number" and type(young_per_egg[2]) ~= "number") then
      -- if only one number provided, use that
      young_per_egg = {young_per_egg[1],young_per_egg[1]}
    elseif (type(young_per_egg[1]) ~= "number" and type(young_per_egg[2]) ~= "number") then
      return
    end
    young_per_egg = random(young_per_egg[1],young_per_egg[2])
  end
  
  if (type(young_per_egg) == "number") then
    return young_per_egg
  else
    return
  end
end

----------------------------------------------------
--release offspring from an egg (called from timers)
function animals.hatch_egg(self, pos, medium, replace, name) -- self, position, medium (to spawn entities in - can be nil), replace (replace with - can be nil), name (optional, but required if not included in self)
  if (type(self) ~= "table" and type(self) ~= "userdata") then
    return false
  end
  
  if (medium == nil or medium == "") then
    medium = "air"
  end
  if (replace == nil or replace == "") then
    replace = "air"
  end
   
  local energy_egg = self.energy_egg 
  local meta = minetest.get_meta(pos):get_float("energy_egg")
  if (meta > 0) then
    energy_egg = meta
  end
  local young_per_egg = animals.calculate_egg_young(self)
  local max_pop = self.max_pop or max_objects
  if (type(name) ~= "string") then
    name = self.name
  end
  
  if not name or not energy_egg or not young_per_egg then
    return false
  end
  if (energy_egg < 0) then
    return false
  end

   local air = minetest.find_nodes_in_area(
      {x=pos.x-1, y=pos.y-1, z=pos.z-1},
      {x=pos.x+1, y=pos.y+1, z=pos.z+1}, {medium})
  --if can't find the stuff this mob moves through then it dies
	if #air < 1 then
		minetest.set_node(pos, {name = replace})
		return false
	end

  -- remove male or baby identifier when checking names
  local check_name = string.gsub(name,"_male","")
  check_name = string.gsub(name,"_baby","")

  local cnt = 0
  local start_e = math.floor(energy_egg/young_per_egg)
  local objcount = #animals.get_entities_inside_radius(check_name, pos, mo_check_radius)
  for i = 1, young_per_egg, 1 do
    if (objcount >= max_pop) then
      break
    end
    local ran_pos = air[random(#air)]
    local ent = minetest.add_entity(ran_pos, name)
    minetest.sound_play("animals_hatch_egg", {pos = pos, gain = 0.8, max_hear_distance = 8})
    ent = ent:get_luaentity()
    mobkit.remember(ent,'energy', start_e)
    mobkit.remember(ent,'age',0)
    objcount = objcount + 1
  end

  minetest.set_node(pos, {name = replace})
  return false

end

 --------------------------------------------------------------------------
 --Movement
 --------------------------------------------------------------------------



----------------------------------------------
--roam to places with equal or lesser darkness
function animals.hq_roam_dark(self,prty)
  local timer = time() + 30
  local func=function(self)
    if time() > timer then
      return true
    end

    local function light_check(pos,tpos)
      if not pos then
        pos = mobkit.get_stand_pos(self)
      end
      if not tpos then
        return false
      end
      local light = minetest.get_node_light(pos, 0.5) or 0
      local lightn = minetest.get_node_light(tpos, 0.5) or 0

      if (lightn <= light) then
        return true
      elseif (lightn < light) then
        return "desirable"
      end
    end

    if (mobkit.is_queue_empty_low(self) and self.isonground) or (prty >= 45 and self.isonground) then
      local light_valid = false
       local pos = mobkit.get_stand_pos(self)
       local neighbor = random(8)

       local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(self,neighbor)

      if (tpos) then
        local temp = climate.get_point_temp(tpos, true)
        if not (animals.temp_comfy(self,temp)) then
          -- do not go to this position
          height = nil
        end
      end
      if (prty >= 45) then
        local numstring
        local bl_pos -- bestlight_pos
        for i = 1, 8, 1 do
          local h, tp, lf
          numstring, h, tp, lf = get_reachable_node(self,numstring) -- shortened versions of "height, tpos, liquidflag"

          if (tp and animals.temp_comfy(self,tp)) then
            local l_check = light_check(bl_pos,tp)
            if (l_check == "desirable") then
              height, tpos, liquidflag = h, tp, lf
              bl_pos = tp
              break
            elseif (l_check == true) then
              height, tpos, liquidflag = h, tp, lf
              bl_pos = tp
            end
          end
        end
        if bl_pos then
          light_valid = true
        elseif (random(1,8) == 8) then
          -- go to a bad area to find better dark
          light_valid = true
        end
      else
        if light_check(pos,tpos) then
          light_valid = true
        end
      end

      if height and not liquidflag then
        if light_valid then
          if (prty >= 45) then
            mobkit.dumbstep(self,height,tpos,1)
          else
            mobkit.dumbstep(self,height,tpos,0.3)
          end
          return false
        else
          return true
        end
      end
		end
	end
	mobkit.queue_high(self,func,prty)
end



----------------------------------------------
--roam to places with comfortable temperature
function animals.hq_roam_comfort_temp(self,prty)
  local timer = time() + 30

  local func = function(self)
    if time() > timer then
      return true
    end

    if (mobkit.is_queue_empty_low(self) or prty >= 35) and self.isonground then
       -- mobkit.is_queue_empty_low(self)
      local min_temp = self.min_temp or 0
      local max_temp = self.max_temp or 20

      local pos = mobkit.get_stand_pos(self)
      local temp = climate.get_point_temp(pos, true)

      if (animals.temp_comfy(self,temp)) then
        -- if temperature is comfortable then end the search
        return true
      end

      local numstring = 12345678
      -- save as a string (or num :D) cause idk,
      -- maybe better memory and storage wise?

      local height, tpos, liquidflag
      local best_temp
      for i = 1, 8, 1 do -- try 8 times to find a good node
        local h, tp, lf
        numstring, h, tp, lf = get_reachable_node(self,numstring)
	-- shortened versions of "height, tpos, liquidflag"

        if (h and not lf) then -- if height somethin' and if provided pos is not a liquid
          local tempn = climate.get_point_temp(tp, true)
          local temp_c,temp_s = animals.temp_comfy(self,tempn)
	  -- temp_comfy (is the provided pos a comfortable temp?),
	  --  temp_status (utilized to check whether too hot or too cold)

          if (temp_s or temp_c == true) then
            -- let's make sure the animal goes to the best suitable temperature
            local old_bt = best_temp -- old_best_temp - used for comparison
            if (type(best_temp) ~= "number" or
            (temp_s == "hot" and tempn < best_temp and tempn > min_temp) or
            (temp_s == "cold" and tempn > best_temp and tempn < max_temp)
	    -- additional check to prevent creatures running into fires to
	    --  warm themselves
            ) then
	       -- if a best_temp hasn't been specified or a better temperature
	       --  has been found for seeking comfy temperatures
	       --  then change best_temp! :D
	       best_temp = tempn
            end

            if ((random(4) == 4 and tempn == best_temp
		 or random(16) == 16) or best_temp ~= old_bt) then
	       -- 1 in 4 chance to choose a different position
	       --  (only if best_temp is equal to tempn - no running into
	       --  fire or coldness)
	       -- 1 in 16 chance just to say screw it and go to a bad temp
	       -- update height, tpos, and liquidflag if a better position
	       --  has been found
	       height, tpos, liquidflag = h, tp, lf
	       -- set height, tpos, and liquidflag
            end

            if (temp_c == true) then
              -- found a good pos to go to, break loop
              break
              -- if a good pos can't be found, the above if statement mess will determine the most optimal area to go
              -- to look for better temperatures
            end
          end
        end
      end

      if height and not liquidflag then
        -- run to that safe (or somewhat safe) pos!
        local spd_f = 0.3 -- speed factor
        if (prty >= 35) then
          spd_f = spd_f * (2 * (prty/35) )
        end
        mobkit.dumbstep(self,height,tpos,spd_f)
      else
        -- could not find a proper node, end search
        return true
      end
    end
  end
  mobkit.queue_high(self,func,prty)
end


----------------------------------------------
--roam to a better surface (by group)
function animals.hq_roam_surface_group(self, group, prty)
  local timer = time() + 15

  local func=function(self)

    if time() > timer then
      return true
    end

    if mobkit.is_queue_empty_low(self) and self.isonground then
      local neighbor = random(8)

      local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(self, neighbor)

      if (tpos) then
        local temp = climate.get_point_temp(tpos, true)
        if not (animals.temp_comfy(self,temp)) then
          -- do not go to this position
          height = nil
        end
      end

      if height and not liquidflag then
        --is it the correct group?
        local s_pos = tpos
        s_pos.y = s_pos.y - 1
        local under = minetest.get_node(s_pos)

        if under and minetest.get_item_group(under.name, group) > 0 then
          mobkit.dumbstep(self, height, tpos, 0.3)
        else
          return true
        end
      end

    end
  end
  mobkit.queue_high(self,func,prty)
end


----------------------------------------------
--roam to a walkable (by group) i.e. walk into the node itself c.f. under
function animals.hq_roam_walkable_group(self, groups, iggroups, prty)
   -- self, groups (table or string), ignoregroups (table or string), priority
  local timer = time() + 15

  if (type(groups) == "string") then
    groups = {groups}
  elseif (type(groups) ~= "table") then
    groups = {}
  end
  if (type(iggroups) == "string") then
    iggroups = {iggroups}
  elseif (type(iggroups) ~= "table") then
    iggroups = {}
  end

  local func=function(self)

    if time() > timer then
      return true
    end

    if mobkit.is_queue_empty_low(self) and self.isonground then
       local neighbor = random(8)

       local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(
	  self, neighbor)

      if (tpos) then
        local temp = climate.get_point_temp(tpos, true)
        if not (animals.temp_comfy(self,temp)) then
          -- do not go to this position
          height = nil
        end
      end

       if height and not liquidflag then
        --is it the correct?
        local n_node = minetest.get_node(tpos).name

        local nodeapp = true -- node appropriate -- if node should be walked to
        for _,group in pairs(iggroups) do
          if (minetest.get_item_group(n_node,group) > 0) then -- if node is in a group that is to be ignored...
            nodeapp = false
            break
          end
        end
        if (nodeapp == false) then
          -- found a node to be ignored oop, don't walk to it
          return true
        end
        for _,group in pairs(groups) do
          if (minetest.get_item_group(n_node,group) > 0) then -- if node is in a specified group then...
            -- let's go it :D
            break
          end
        end

        if (nodeapp == true) then
          mobkit.dumbstep(self, height, tpos, 0.3)
        else
          return true
        end
      end

    end
  end
  mobkit.queue_high(self,func,prty)
end


local function aqua_path_safe(start_pos,p)
	local path=minetest.raycast(start_pos,p,false,true)
	for pointed_thing in path do
		local node=mobkit.nodeatpos(pointed_thing.intersection_point)
		if node and node.drawtype ~= 'liquid' then
			return false
		end
	end
	return true
end


 ---------------------------------------------------
--(currently duplicated in mobkit, but only as a local function)
local function aqua_radar_dumb(pos,yaw,range,reverse)
 range = range or 4
 local function okpos(p,start_pos)
   local node = mobkit.nodeatpos(p)
   if node then
     if node.drawtype == 'liquid' then
       local nodeu = mobkit.nodeatpos(mobkit.pos_shift(p,{y=1}))
       local noded = mobkit.nodeatpos(mobkit.pos_shift(p,{y=-1}))
       if ((nodeu and nodeu.drawtype == 'liquid') or (noded and noded.drawtype == 'liquid')) then
         return true
       else
         return false
       end
     else
       local h,_ = mobkit.get_terrain_height(p)
       if h then
         local node2 = mobkit.nodeatpos({x=p.x,y=h+1.99,z=p.z})
         if node2 and node2.drawtype == 'liquid' then
		 return true, h
	 end
       else
         return false
       end
     end
   else
     return false
   end
 end
-- check node in front at range.
 local fpos = mobkit.pos_translate2d(pos,yaw,range)
 local ok,h = okpos(fpos,pos)


 if not ok then
--check nodes right and left of possition.
--Reverse checks from back to front first
   local ffrom, fto, fstep
   if reverse then
     ffrom, fto, fstep = 3,1,-1
   else
     ffrom, fto, fstep = 1,3,1
   end
   for i=ffrom, fto, fstep  do
     ok,h = okpos(mobkit.pos_translate2d(pos,yaw+i,range),pos)
     if ok then
       return yaw+i,h
     end
     ok,h = okpos(mobkit.pos_translate2d(pos,yaw-i,range),pos)
     if ok then
       return yaw-i,h
     end
   end
   -- No safe path so reverse direction.
   return yaw+pi,h
 else
   return yaw, h
 end
end


---------------------------------------------------
-- turn around  from opos and swim away until out of sight
function animals.hq_swimfrompos(self,prty,opos,speed)
  local timer = time() + 2
  local func = function(self)

    if time() > timer then
      return true
    end

    local pos = mobkit.get_stand_pos(self)
    local distance = vector.distance(pos,opos)
    -- rotate 30 degrees to right from current yaw
    local yaw = self.object:get_yaw() - pi/6
    if distance > 0.5 then
	-- or 180 from pos we're running from if no longer close to it
	yaw = get_yaw_to_object(pos, opos) - pi
    end


    if (distance/1.5) < self.view_range then
      local swimto, height = aqua_radar_dumb(pos,yaw,1)
      if height and height > pos.y then
        local vel = self.object:get_velocity()
        vel.y = vel.y+0.2
        self.object:set_velocity(vel)
      end

      mobkit.hq_aqua_turn(self,prty,swimto,speed)

    else
      return true
    end

  end
  mobkit.queue_high(self,func,prty)
 end



---------------------------------------------------
-- turn around  from tgtob and swim away until out of sight
function animals.hq_swimfrom(self,prty,tgtobj,speed)
  local timer = time() + 2

  local func = function(self)

    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then
      return true
    end
    local pos = mobkit.get_stand_pos(self)
    local opos = tgtobj:get_pos()

    local yaw = get_yaw_to_object(pos, opos) - (pi/2)
    local distance = vector.distance(pos,opos)

    if (distance/1.5) < self.view_range then
      local swimto, height = aqua_radar_dumb(pos,yaw,speed)
      if height and height > pos.y then
        local vel = self.object:get_velocity()
        vel.y = vel.y+0.1
        self.object:set_velocity(vel)
      end

      mobkit.hq_aqua_turn(self,prty,swimto,speed)

    else
      return true
    end

  end
  mobkit.queue_high(self,func,prty)
 end




 ---------------------------------------------------
 -- chase tgtob until somewhat out of sight
function mobkit.hq_chaseafter(self,prty,tgtobj)
  local timer = time() + 3

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then return true end

    if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			if vector.distance(pos,opos) > 3 then
        mobkit.make_sound(self,'warn')
				mobkit.goto_next_waypoint(self,opos)
			else
				mobkit.lq_idle(self,1)
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

 ---------------------------------------------------
 -- chase tgtob and swim until somewhat out of sight
 function animals.hq_swimafter(self,prty,tgtobj,speed)
   local timer = time() + 3

   local func = function(self)
     if time() > timer then
       return true
     end

     if not mobkit.is_alive(tgtobj) then
       return true
     end

     local pos = mobkit.get_stand_pos(self)
     local opos = tgtobj:get_pos()

     local yaw = get_yaw_to_object(pos, opos) -pi
     local distance = vector.distance(pos,opos)

     if distance < self.view_range/3 then
       local swimto, height = aqua_radar_dumb(pos,yaw,3)
       if height and height > pos.y then
         local vel = self.object:get_velocity()
         vel.y = vel.y+0.1
         self.object:set_velocity(vel)
       end

       mobkit.hq_aqua_turn(self,prty,swimto,speed)

     else
       return true
     end

   end
   mobkit.queue_high(self,func,prty)
 end





--------------------------------------------------------------------------
--Attack and feeding
--------------------------------------------------------------------------

----------------------------------------------------------------
--on_punch
function animals.on_punch(self, tool_capabilities, puncher, prty, chance)
  --[[
  if mobkit.is_alive(self) then
    mobkit.make_sound(self,'punch')
    local multiplier = tool_capabilities.full_punch_interval or 0.1
    multiplier = math_clamp(multiplier / time_from_last_punch, 0, 1)
    local dmg = tool_capabilities.damage_groups.fleshy or 1
    dmg = math.floor(dmg * multiplier)
    animals.modify_hp(self,-dmg)

    local conserve = mobkit.recall(self,'conserve')
    if (self.hp < self.max_hp/10 or self.hp <= (dmg * 2) or conserve == true) then
      mobkit.animate(self,'fast')
      if self.class == 2 then
        animals.hq_swimfrom(self, prty, puncher, self.max_speed)
        flee_sound(self)
      else
        mobkit.make_sound(self,'warn')
        mobkit.hq_runfrom(self, prty, puncher)
      end
    elseif prty < 20 then
      animals.fight_or_flight(self, puncher, prty, chance)
    end
  end
  --]]
  if mobkit.is_alive(self) then
    --do damage
    mobkit.clear_queue_high(self)
    local conserve = mobkit.recall(self,'conserve')
    local dmg = tool_capabilities.damage_groups.fleshy or 1
    animals.modify_hp(self,-dmg)
    mobkit.make_sound(self,'punch')
    --fight or flight
    --flee if hurt (or hibernating!)
    if self.hp < self.max_hp/10 or self.hp <= (dmg * 2) or conserve == true then
      mobkit.animate(self,'fast')
      mobkit.make_sound(self,'warn')
      mobkit.hq_runfrom(self, prty, puncher)
    elseif prty < 20 then
      animals.fight_or_flight(self, puncher, prty, chance)
    end


  end
end


function animals.on_punch_water(self, tool_capabilities, puncher, prty, chance)
  if mobkit.is_alive(self) then
    --do damage
    mobkit.clear_queue_high(self)
    local dmg = tool_capabilities.damage_groups.fleshy or 1
    animals.modify_hp(self,-dmg)
    mobkit.make_sound(self,'punch')

    --fight or flight
    if self.hp < self.max_hp/10 then
      mobkit.animate(self,'fast')
      animals.hq_swimfrom(self, prty, puncher, self.max_speed)
      flee_sound(self)
    else
      animals.fight_or_flight_water(self, puncher, prty, chance)
    end

  end
end

----------------------------------------------------------------
--attack or run vs player
function animals.fight_or_flight_plyr(self, plyr, prty, chance)
  mobkit.clear_queue_high(self)
  --fight chance, or run away (don't do it attach bc buggers physics)
  if random()< chance and plyr:get_attach() == nil then
    mobkit.hq_warn(self,prty,plyr)
  else
    --mobkit.animate(self,'fast')
    --mobkit.make_sound(self,'scared')
    mobkit.hq_runfrom(self,prty, plyr)
  end
end

--attack or run vs entity
function animals.fight_or_flight(self, threat, prty, chance)
  mobkit.clear_queue_high(self)
  --fight chance, or run away
  if random()< chance then
    mobkit.hq_warn(self,prty, threat)
  else
    --mobkit.animate(self,'fast')
    --mobkit.make_sound(self,'scared')
    mobkit.hq_runfrom(self,prty, threat)
  end
end




----attack or run vs player in water
function animals.fight_or_flight_plyr_water(self, plyr, prty, chance)
  mobkit.clear_queue_high(self)
  --ignore chance, or run away
  if random()< chance and plyr:get_attach() == nil then
    mobkit.hq_aqua_attack(self, prty, plyr, self.max_speed)
  else
    mobkit.animate(self,'fast')
    animals.hq_swimfrom(self, prty, plyr, self.max_speed)
    flee_sound(self)
  end
end

----attack or run vs player in water
function animals.fight_or_flight_water(self, threat, prty, chance)
  mobkit.clear_queue_high(self)
  --ignore chance, or run away
  if random()< chance then
    mobkit.hq_aqua_attack(self, prty, threat, self.max_speed)
  else
    mobkit.animate(self,'fast')
    animals.hq_swimfrom(self, prty, threat, self.max_speed)
    flee_sound(self)
  end
end

----------------------------------------------------------------
--Find and Flee predators
function animals.predator_avoid(self, prty, chance)

  for  _, pred in ipairs(self.predators) do
    local thr = mobkit.get_closest_entity(self,pred)
    if thr then
      animals.fight_or_flight(self, thr, prty, chance)
      return thr
    end
  end
end


function animals.predator_avoid_water(self, prty, chance)

  for  _, pred in ipairs(self.predators) do
    local thr = mobkit.get_closest_entity(self,pred)
    if thr then
      animals.fight_or_flight_water(self, thr, prty, chance)
      return thr
    end
  end
end

----------------------------------------------------------------
--Find and hunt prey
function animals.prey_hunt(self, prty)

  for  _, prey in ipairs(self.prey) do
    local tgtobj = mobkit.get_closest_entity(self,prey)
    --if tgtobj then
      --animals.hq_attack_eat(self,prty,tgtobj)
      --return true
    --end
    if tgtobj then
      local tgtpos = tgtobj:get_pos()
      local drawtype = node_drawtype(tgtpos)
      if (drawtype == "liquid" and self.oxygen_min) then
        -- look for a solid node underneath (safe to hunt) and if meant to hunt prey that's in water
        tgtpos = mobkit.pos_shift(tgtpos,{y = -1})
        drawtype = node_drawtype(tgtpos)
      end
      
      if (drawtype ~= "liquid") then
        animals.hq_attack_eat(self,prty,tgtobj)
        return true
      end
    end
  end
end


function animals.prey_hunt_water(self, prty)

  for  _, prey in ipairs(self.prey) do
    local tgtobj = mobkit.get_closest_entity(self,prey)
    if tgtobj then
      local tgtpos = tgtobj:get_pos()
      local drawtype = node_drawtype(tgtpos)
      if (drawtype ~= "liquid") then
        -- look for a liquid node underneath >:D
        tgtpos = mobkit.pos_shift(tgtpos,{y = -1})
        drawtype = node_drawtype(tgtpos)
        if (drawtype == "airlike") then
          -- in case they're a bit too high lol
          tgtpos = mobkit.pos_shift(tgtpos,{y = -1})
          drawtype = node_drawtype(tgtpos)
        end
      end
      
      if (drawtype == "liquid") then
        mobkit.animate(self,'fast')
        flee_sound(self)
        animals.hq_aqua_attack_eat(self, prty, tgtobj, self.max_speed)
        return true
      end
    end
  end
end




----------------------------------------------------
--for things that eat spreading surface
function animals.eat_spreading_under(pos, chance)
  local p = mobkit.get_node_pos(pos)
  local posu = {x = p.x, y = p.y - 1, z = p.z}
  local under = minetest.get_node(posu).name

  if minetest.get_item_group(under, "spreading") > 0 then
    if random()< chance then
      --set node to it's drop
      --this is to scratch up surface layers
      local nodedef = minetest.registered_nodes[under]
      local drop = nodedef.drop
      minetest.check_for_falling(posu)
      minetest.set_node(posu, {name = drop})
      minetest.sound_play("nodes_nature_dig_crumbly", {gain = 0.2, pos = pos, max_hear_distance = 10})
    end

    return true

  else
    return false
  end

end

----------------------------------------------------
-- sediment eating functions

-- modifies the provided sediment at pos
local function eat_sediment(pos,nodedef,grassy)
  --set node to it's drop
  --this is to scratch up surface layers
  if (type(nodedef) == "string") then
    -- got a name, find it
    nodedef = minetest.registered_nodes[nodedef]
  end
  if (type(nodedef) ~= "table") then
    -- don't cause error
    return
  end
  if nodedef.param1 or nodedef.param2 then
    -- got passed the get_node() instead of table
    if not (nodedef.name) then
      return
    else
      nodedef = minetest.registered_nodes[nodedef.name]
      if not nodedef then
        -- couldn't find nodedef, don't error
        return
      end
    end
  end
  
  if (minetest.get_item_group(nodedef.name,"spreading") > 0 and grassy == true) then
    -- it's a grass, let's eat it and modify it (and if eating grass was desired)
    local sediment_name = nodedef._wet_salty_name -- use this to get the raw sediment
    -- (grassy _wet_salty variations of sediments do not exist)
    local other_nodedef
    if (sediment_name) then
      sediment_name = string.gsub(sediment_name,"_wet_salty","") -- get raw sediment
      other_nodedef = minetest.registered_nodes[sediment_name]
    end
    if (other_nodedef) then
      if (string.match(nodedef.name,"_wet")) then
        -- get wet if the grassy node is wet
        local wet_name = other_nodedef._wet_name
        
        other_nodedef = minetest.registered_nodes[wet_name]
      end
    end
    if (other_nodedef and other_nodedef.name) then
      -- get the non-spreading version of the node (does not account for naturalslopes)
      minetest.add_node(pos, {name = other_nodedef.name})
    end
  end
  
  -- no idea what this "drop" is supposed to do
  local drop = nodedef.drop
  minetest.set_node(pos, {name = drop})
  minetest.check_for_falling(pos)
  minetest.sound_play("nodes_nature_dig_crumbly", {gain = 0.2, pos = pos, max_hear_distance = 10})
end

--for things that eat sediment (i.e. dig in the mud)
function animals.eat_sediment_under(pos, chance)
  local p = mobkit.get_node_pos(pos)
  local posu = {x = p.x, y = p.y - 1, z = p.z}
  local under = minetest.get_node(posu).name

  if minetest.get_item_group(under, "sediment") > 0 then
    -- CONSUME
    if random()< chance then
      -- GET DROPS (idk how that works lol)
      eat_sediment(posu,under)
    end

    return true
  else
    return false
  end
end

-- eat grassy nodes with a chance of modifying the grass node to its non-grassy self (does not respect naturalslopes)
function animals.eat_grassy_sediment_under(pos, chance)
  -- only eat grassy lol
  local p = mobkit.get_node_pos(pos)
  local posu = {x = p.x, y = p.y - 1, z = p.z}
  local under = minetest.get_node(posu).name

  if (minetest.get_item_group(under, "sediment") > 0 and minetest.get_item_group(under,"spreading") > 0 ) then
    -- CONSUME
    if random()< chance then
      -- MODIFY
      eat_sediment(posu,under,true)
    end

    return true
  else
    return false
  end
end


----------------------------------------------------
--eating any flora

function animals.eat_flora(pos, chance)
  local p = mobkit.get_node_pos(pos)
  local node = minetest.get_node(p).name

  if minetest.get_item_group(node, "flora") > 0
  and minetest.get_item_group(node, "cane_plant") == 0
  then
    --gain energy
    if random()< chance then
      --destroy the plant
      minetest.set_node(p, {name = 'air'})
      minetest.sound_play("nodes_nature_dig_snappy", {gain = 0.2, pos = pos, max_hear_distance = 10})
    end

    return true
  else
    return false
  end
end

----------------------------------------------------------------
-- consume targeted creature
local function consume_target(self,target)
  local targ_specs = animals.get_structure(target)
  if not self or not targ_specs then
    return
  end
  local ent = targ_specs.ent
  local ent_hp = ent.hp
  local ent_mhp = ent.max_hp
  if not ent_hp or not ent_mhp then
    return
  end

  local tflp = get_time(self.did_last_punch) -- time from last punch
  target:punch(self.object,tflp,self.attack)
  self.did_last_punch = get_time()
  local dmg = (ent_hp - ent.hp) -- health subtracted after punch

  if dmg > 0 then
    dmg = math_clamp(dmg,0,ent_mhp) -- prevent accidental excessive energygain by clamping below max_hp
    -- eat bits of opponent
    local ent_e = (mobkit.recall(ent,'energy') or 1)
    local self_e = (mobkit.recall(self,'energy') or 1)
    local energygain = (ent_e * (dmg / ent_mhp) ) -- omnomnom

    mobkit.remember(self,'energy', (energygain*0.3)  + self_e) -- take 30%
    mobkit.remember(ent,'energy', ent_e - energygain) -- make opponent lose energy

    if (ent.hp <= dmg) then
      mobkit.remember(self,'energy', (ent_e*0.9) + self_e) -- add 90% of opponent's energy for nomming fully
      ent.object:remove()
      return true
    end
  end
  return false
end


----------------------------------------------------------------
--like mobkit version, but including removal of prey and gaining energy
--to hit is to catch... for predators, where the chewing does the killing
function animals.hq_aqua_attack_eat(self,prty,tgtobj,speed)
 local timer = time() + 12

	local tyaw = 0
	local prvscanpos = {x=0,y=0,z=0}
	local init = true
	local tgtbox = tgtobj:get_properties().collisionbox

	local func = function(self)
  if time() > timer then
    return true
  end

		if not mobkit.is_alive(tgtobj) then
    return true
  end

		if init then
			mobkit.animate(self,'fast')
			mobkit.make_sound(self,'attack')
			init = false
		end

		local pos = mobkit.get_stand_pos(self)
		local yaw = self.object:get_yaw()
		local scanpos = mobkit.get_node_pos(mobkit.pos_translate2d(pos,yaw,speed))
		if not vector.equals(prvscanpos,scanpos) then
			prvscanpos=scanpos
			local nyaw,height = aqua_radar_dumb(pos,yaw,speed*0.5)
			if height and height > pos.y then
				local vel = self.object:get_velocity()
				vel.y = vel.y+1
				self.object:set_velocity(vel)
			end
			if yaw ~= nyaw then
				tyaw=nyaw
				mobkit.hq_aqua_turn(self,prty+1,tyaw,speed)
				return
			end
		end

		local tpos = tgtobj:get_pos()
		tyaw=minetest.dir_to_yaw(vector.direction(pos,tpos))
		mobkit.turn2yaw(self,tyaw,3)
		yaw = self.object:get_yaw()
		if mobkit.timer(self,1) then
			if not mobkit.is_in_deep(tgtobj) then return true end
			local vel = self.object:get_velocity()
			if tpos.y>pos.y+0.5 then self.object:set_velocity({x=vel.x,y=vel.y+0.5,z=vel.z})
			elseif tpos.y<pos.y-0.5 then self.object:set_velocity({x=vel.x,y=vel.y-0.5,z=vel.z}) end
		end
		if mobkit.is_pos_in_box(mobkit.pos_translate2d(pos,yaw,self.attack.range),tpos,tgtbox) then	--bite
      mobkit.make_sound(self,'bite')
			mobkit.hq_aqua_turn(self,prty,yaw-pi,speed)
      return consume_target(self,tgtobj)
		end
		mobkit.go_forward_horizontal(self,speed)
	end
  mobkit.queue_high(self,func,prty)
end





---------------------------------------------------
--like mobkit version, but including removal of prey and gaining energy
--to hit is to catch... for predators, where the chewing does the killing
local function lq_jumpattack_eat(self,height,target)
	local phase=1
	local tgtbox = target:get_properties().collisionbox

	local func=function(self)
		if not mobkit.is_alive(target) then return true end
    
		if self.isonground then
			if phase==1 then	-- collision bug workaround
				local vel = self.object:get_velocity()
				vel.y = -mobkit.gravity*sqrt(height*2/-mobkit.gravity)
				self.object:set_velocity(vel)
				mobkit.make_sound(self,'charge')
				phase=2
			else
				mobkit.lq_idle(self,0.3)
				return true
			end
		elseif phase==2 then
			local dir = minetest.yaw_to_dir(self.object:get_yaw())
			local vy = self.object:get_velocity().y
			dir=vector.multiply(dir,6)
			dir.y=vy
			self.object:set_velocity(dir)
			phase=3
		elseif phase==3 then	-- in air
			local tgtpos = target:get_pos()
			local pos = self.object:get_pos()
      
      local dist = vector.distance(tgtpos,pos)
      
			-- calculate attack spot
			local yaw = self.object:get_yaw()
			local dir = minetest.yaw_to_dir(yaw)
			local apos = mobkit.pos_translate2d(pos,yaw,self.attack.range)

			if mobkit.is_pos_in_box(apos,tgtpos,tgtbox)
      or (mobkit.isnear2d(pos,tgtpos,1) and random()<0.1) --makes up for issue with some boxes not working together
      then	--bite
        	-- bounce off
				local vy = self.object:get_velocity().y
				self.object:set_velocity({x=dir.x*-3,y=vy,z=dir.z*-3})
					-- play attack sound if defined
				mobkit.make_sound(self,'attack')
				phase=4
        
        -- eat bits of opponent
        return consume_target(self,target)
        
			end
		end
	end
	mobkit.queue_low(self,func)
end



function animals.hq_attack_eat(self,prty,tgtobj)
  local timer = time() + 12

	local func = function(self)
    if time() > timer then
      return true
    end

		if not mobkit.is_alive(tgtobj) then return true end

		if mobkit.is_queue_empty_low(self) then
      local pos = mobkit.get_stand_pos(self)
		--	local pos = mobkit.get_stand_pos(self)
			local tpos = mobkit.get_stand_pos(tgtobj)
			local dist = vector.distance(pos,tpos)
			if dist > 3 then
				return true
			else
			   mobkit.lq_turn2pos(self,tpos)
			   local tgtheight = tgtobj:get_luaentity().height
			   if tgtheight == nil then
			      tgtheight = 0
			   end
        local height = tgtobj:is_player() and 0.35 or tgtheight*0.6
				if tpos.y+height>pos.y then
					lq_jumpattack_eat(self,tpos.y+height-pos.y,tgtobj)

				else
					mobkit.lq_dumbwalk(self,mobkit.pos_shift(tpos,{x=random()-0.5,z=random()-0.5}))
				end
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end





----------------------------------------------------------------
--Social Behaviour


----------------------------------------------------------------
--territorial behaviour
--avoid those in better condition
function animals.territorial(self, energy, eat)

  for  _, riv in ipairs(self.rivals) do

    local rival = mobkit.get_closest_entity(self, riv)

    if rival then

      --flee if hurt
      if self.hp < self.max_hp/4 then
        mobkit.animate(self,'fast')
        mobkit.make_sound(self,'warn')
        mobkit.hq_runfrom(self, 25, rival)
        return true
      end

      --contest! The more energetic one wins
      local r_ent = rival:get_luaentity()
      local r_ent_e = mobkit.recall(r_ent,'energy') or 0

      if energy > r_ent_e then
        if eat then
          animals.hq_attack_eat(self, 25, rival)
        else
          mobkit.animate(self,'fast')
          mobkit.make_sound(self,'warn')
          mobkit.hq_chaseafter(self,25,rival)
        end
        return true
      else
        mobkit.animate(self,'fast')
        mobkit.make_sound(self,'warn')
        mobkit.hq_runfrom(self,25,rival)
        return true
      end
    end

  end

end


--water version
function animals.territorial_water(self, energy, eat)

  for  _, riv in ipairs(self.rivals) do

    local rival = mobkit.get_closest_entity(self, riv)

    if rival then

      --flee if hurt
      if self.hp < self.max_hp/4 then
        mobkit.animate(self,'fast')
        flee_sound(self)
        animals.hq_swimfrom(self, 25, rival ,self.max_speed)
        return true
      end

      --contest! The more energetic one wins
      local r_ent = rival:get_luaentity()
      local r_ent_e = mobkit.recall(r_ent,'energy')

      --not clear why some have nil, but it happens
      if r_ent_e == nil then
        return
      end

      if energy > r_ent_e then
        if eat then
          animals.hq_aqua_attack_eat(self, 25, rival, self.max_speed)
          flee_sound(self)
        else
          --harass
          mobkit.animate(self,'fast')
          animals.hq_swimafter(self, 15, rival, self.max_speed)
          flee_sound(self)
        end
        return true
      else
        mobkit.animate(self,'fast')
        flee_sound(self)
        animals.hq_swimfrom(self, 25, rival ,self.max_speed)
        return true
      end
    end

  end

end


----------------------------------------------------------------
--flocking behaviour
--follow friends

function animals.hq_flock(self,prty,tgtobj, min_dist)
  local timer = time() + 5

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then return true end

    if mobkit.is_queue_empty_low(self) then
      local pos = mobkit.get_stand_pos(self)
      local tpos = mobkit.get_stand_pos(tgtobj)
      local dist = vector.distance(pos,tpos)
      if dist <= min_dist then
        mobkit.lq_idle(self,1)
        return true
      else
        mobkit.goto_next_waypoint(self,tpos)
      end
    end
  end

  mobkit.queue_high(self,func,prty)
end



function animals.hq_flock_water(self,prty,tgtobj, min_dist, speed)
  local timer = time() + 7

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then
      return true
    end

    local pos = mobkit.get_stand_pos(self)
    local opos = tgtobj:get_pos()

    local yaw = get_yaw_to_object(pos, opos) - (pi/2)
    local distance = vector.distance(pos,opos)

    if distance > min_dist then
      local swimto, height = aqua_radar_dumb(pos,yaw,3)
      if height and height > pos.y then
        local vel = self.object:get_velocity()
        vel.y = vel.y+0.1
        self.object:set_velocity(vel)
      end

      mobkit.hq_aqua_turn(self,prty,swimto,speed)

    else
      --sync with target
      local tvel = tgtobj:get_velocity()
      local tyaw = tgtobj:get_yaw()

      mobkit.hq_aqua_turn(self,prty+1,tyaw,tvel)
      mobkit.make_sound(self,'call')
      return true
    end

  end
  mobkit.queue_high(self,func,prty)
 end







function animals.flock(self, prty, min_dist, aqua_speed)

  for  _, fr in ipairs(self.friends) do

    --local friend = mobkit.get_closest_entity(self, fr)
    local friend =mobkit.get_nearby_entity(self, fr)

    if friend then
      --get distance, if too far away go to them
      if aqua_speed then
        mobkit.animate(self,'walk')
        mobkit.make_sound(self,'call')
        animals.hq_flock_water(self, prty, friend, min_dist, aqua_speed)
      else
        mobkit.animate(self,'walk')
        mobkit.make_sound(self,'call')
        animals.hq_flock(self, prty, friend, min_dist)
      end
      return
    end
  end

end

----------------------------------------------------------------
--mate
--go after them, if close enough do the deed
function animals.hq_mate(self,prty,tgtobj)
  local timer = time() + 10

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then return true end

    if mobkit.is_queue_empty_low(self) then
      local pos = mobkit.get_stand_pos(self)
      local tpos = mobkit.get_stand_pos(tgtobj)
      local dist = vector.distance(pos,tpos)
      if dist <= self.attack.range then
        mobkit.lq_idle(self,1)
        mobkit.make_sound(self,'mating')
        if self.sex == "male" then
          --get the other one pregnant
          mobkit.remember(tgtobj,'pregnant',true)
        else
          --get pregnant
          mobkit.remember(self,'pregnant',true)
        end
        return true
      else
        mobkit.make_sound(self,'call')
        mobkit.goto_next_waypoint(self,tpos)
      end
    end
  end

  mobkit.queue_high(self,func,prty)
end

--assess potential mate
function animals.mate_assess(self, name)
  local mate = mobkit.get_nearby_entity(self, name)
  if mate then
    --see if they are in the mood
    local ent = mate:get_luaentity()
    local sexy = mobkit.recall(ent,'sexual') or false
    local preg = mobkit.recall(ent,'pregnant') or false
    if sexy == true and preg == false then
      return ent
    else
      return false
    end
  else
    return false
  end

end

function animals.get_entities_inside_radius(creature,pos,radius,match_string)
  if (type(radius) ~= "number") then
    radius = 30
  end
  -- will use string.match if true
  if (type(match_string) ~= "boolean") then
    match_string = true
  end
  -- if provided creature is an entity or objectref
  if (type(creature) == "userdata") then
    if (type(creature["get_luaentity"]) == "function") then
      creature = creature:get_luaentity()
    end
    if (type(creature) ~= "nil" and type(creature) ~= "boolean" and type(creature) ~= "string") then
      creature = creature["name"]
    else
      creature = ""
    end
  end
  
  if (type(creature) ~= "string") then
    creature = "*"
  end
  if (type(pos) ~= "table") then
    return
  end
  if (type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number") then
    minetest.log("warning","animals.get_entities_inside_radius: provided position is invalid")
    return
  end
  
  local objs = minetest.get_objects_inside_radius(pos,radius)
  local aobjs = {}
  
  for _,v in pairs(objs) do
    local name = ""
    local obj
    if (type(v) ~= "nil") then
      obj = v:get_luaentity()
    end
    if (type(obj) ~= "nil") then
      name = obj.name
    end
    if (type(name) == "string") then
      -- if match_string is true, then will use string.match() 
      if (name == creature or creature == "*" or (match_string == true and string.match(creature,name))) then
        aobjs[#aobjs + 1] = v
      end
    end
  end
  
  return aobjs
end



-- Animals Interactors Interactions
animals.interactors = {}
function animals.add_interactors(itype,creature,...) -- interactiontype, creature to be set with properties, all possible creatures to add
  -- adds the minetest luaentity names of creatures to a certain interaction type provided by a specified creature
  -- for example, animals.add_interactor("rivals","pegasun","animals:pegasun") would add the entity "animals:pegasun" to the rivals of "pegasun"
  -- lowercase strings for easier finding and indexing
  if (type(itype) ~= "string") then
    return
  else
    itype = string.lower(itype)
  end
  
  if (type(creature) ~= "string") then
    return
  else
    creature = string.lower(creature)
  end

  local interactable = animals.interactors[creature] -- finds the creature's table provided within animals.interactors
  if (type(interactable) ~= "table") then -- creates new one if not found
    animals.interactors[creature] = {}
    
    interactable = animals.interactors[creature]
  end
  
  local itable = animals.interactors[creature][itype] -- finds the specified interactiontype table within creature's table
  if (type(itable) ~= "table") then -- create new table with the interactiontype if it isn't specified
    animals.interactors[creature][itype] = {}
    
    itable = animals.interactors[creature][itype]
  end

  local posscreatures = {...} -- convert specified creatures into an easily accessible table (the ... for multiple args)
  for _,interactor in pairs(posscreatures) do
    if (type(interactor) == "string") then
      -- allow simplification with "self" parameter
      if interactor == "self" then
        interactor = creature
      end
      -- add said creature as an "interactor" within the provided interactiontype (if specified creature is an entity name)
      itable[#itable + 1] = interactor
    end
  end
  
  return true
end

function animals.get_interactors(creature,itype) -- creature to get stats from, interationtype
  -- get a table of the creatures that interact with the specified creature in the specified interactiontype way
  if (type(itype) ~= "string") then
    return
  else
    itype = string.lower(itype)
  end
  
  if (type(creature) ~= "string") then
    return
  else
    creature = string.lower(creature)
  end
  -- get the creature's interactors table
  local interactable = animals.interactors[creature]
  if (type(interactable) ~= "table") then
    return
  end
  -- get who the creature interacts in what specified way
  local itable = interactable[itype]
  -- return nil (no table found) or the specified table of interaction type
  return itable
end

-------- Mobkit function rewrites

-- makes it so animals do not see or interact with the player (if the animals use this instead of mobkit's) if player is in creative

function animals.get_nearby_player(self,forceplyr)
  -- "forceplyr" bool parameter to force a player despite creative mode
  local plyr = mobkit.get_nearby_player(self) -- get player from mobkit
  if (plyr) then
    -- if player, then check if player is NOT in creative...
    if (not minimal.player_in_creative(plyr) or forceplyr == true) then
      return plyr
    end
  end
end

-- Taken directly from mobkit to properly calculate fall damage
function animals.vitals(self)
	
	
	-- vitals: oxygen
	if self.lung_capacity then
		local colbox = self.object:get_properties().collisionbox
    local lowpos = mobkit.pos_shift(self.object:get_pos(),{y=colbox[5]})
    local drawtype = node_drawtype(lowpos) -- node at hitbox top

    local oxygen_min = self.oxygen_min or self.lung_capacity
    local breathing_rate = self.breating_rate or 1
    -- utilized by non-water animals
    -- determines whether or not the animal should try to get out (if there's too much water)
    local dangerous = false
    if (node_drawtype(mobkit.pos_shift(lowpos,{y=-1})) == "liquid" or node_drawtype(mobkit.pos_shift(lowpos,{y=1})) == "liquid" or oxygen_min == self.lung_capacity) then
      dangerous = true
    end
    
    if (self.class ~= 2 and self.class ~= 3) then
      if drawtype == 'liquid' then
        self.oxygen = math_clamp(self.oxygen - 0.5,0,self.lung_capacity)
        if (self.oxygen <= oxygen_min or dangerous == true) then -- if uncomfortable
          -- swim to shore
          animals.hq_liquid_recovery(self,60) -- LIQUID RECOVERY
        end
      else
        self.oxygen = math_clamp(self.oxygen + breathing_rate,0,self.lung_capacity)
      end
    elseif (self.class ~= 3) then
      if self.isinliquid then
        self.oxygen = math_clamp(self.oxygen + breathing_rate,0,self.lung_capacity)
      else
        self.oxygen = math_clamp(self.oxygen - 0.5,0,self.lung_capacity)
      end
    end
    if (self.class == 3 and self.oxygen < self.lung_capacity) then
      -- amphibians get to breathe wherever they wanna
      self.oxygen = math_clamp(self.oxygen + breathing_rate,0,self.lung_capacity)
    end
			
		if self.oxygen <= 0 then
      -- drown by 10% of max_hp
      local dmg = math_clamp(self.max_hp * 0.1, 1, self.hp)
      animals.modify_hp(self,-dmg)
    end
	end
  return
end

-- rewrite of mobkit's hq_liquid_recovery because it'd literally instakill
function animals.hq_liquid_recovery(self,prty)
  local radius = 1
	local yaw = 0
	local func = function(self)
		if not self.isinliquid then return true end
		local pos=self.object:get_pos()
		local vec = minetest.yaw_to_dir(yaw)
		local pos2 = mobkit.pos_shift(pos,vector.multiply(vec,radius))
		local height, liquidflag = mobkit.get_terrain_height(pos2)
		if height and not liquidflag then
			mobkit.hq_swimto(self,prty,pos2)
			return true
		end
    yaw=yaw+pi*0.25
    if yaw>2*pi then
			radius=radius+1
			if radius > self.view_range then
        yaw = random(0,(yaw+pi*2) * 100) -- random direction attempt (save decimals)
        yaw = yaw/100
        radius = random(math_clamp(3,self.view_range,self.view_range),self.view_range)
        -- swim anywhere! (or try to...)
        mobkit.turn2yaw(self,yaw)
        vec = minetest.yaw_to_dir(yaw)
        pos2 = mobkit.pos_shift(pos,vector.multiply(vec,radius))
        
        if (node_drawtype(pos2) ~= "liquid" or node_drawtype(mobkit.pos_shift(pos2,{y=1})) ~= "liquid") then
          -- made my OWN swimto because mobkit SUCKS 3:<
          pos2 = vector.normalize(vector.direction({x = pos.x, y = pos2.y, z = pos.z}, pos2))
          mobkit.turn2yaw(self,minetest.dir_to_yaw(pos2))
          pos2 = vector.multiply(pos2,3)
          pos2.y = pos2.y + 2
          self.object:set_velocity(pos2)
        end
        
        radius = 1
			end
      yaw = 0
		end
  end
  mobkit.queue_high(self,func,prty)
end



function animals.register_animal(name,def)
  assert(type(name) == "string","animals.register_animal: name is not a string, got '"..tostring(name).."'")
  assert(type(def) == "table","animals.register_animal: definition is not a table, got '"..tostring(def).."'")
  assert(type(def.logic) == "function","animals.register_animal: no 'logic' function provided for definition, got '"..tostring(def.logic).."'")

  local basedef = {
    name = name,
    -- core
    initial_properties = {
      max_hp = 1,

      physical = true,
      collide_with_objects = true,
      collision_box = {-0.1,-0.1,-0.1,0.1,0.1,0.1},
      visual_size = {x = 1, y = 1},
      makes_footstep_sound = true,
      timeout = 0
    },
    -- animal stats
    lung_capacity = 5,
    min_temp = -10,
    max_temp = 10,
    -- animal energy + reproduction stats
    energy_max = 100, -- seconds your animal can survive without food
    lifespan = 500, -- seconds your animals will survive in total
    energy_egg = 20, -- energy that goes to egg
    egg_timer = 60*5, -- seconds until your animal's egg hatches (default 5 minutes - 60*5)
    young_per_egg = 1, -- how many young will hatch from the egg (energy_egg will be divided up to how many offspring spawn
    -- so 4 offspring will have energy_egg be split into 4 (or 20/4 = 5 units) for each of the young)
    -- can be a table, such as {1,3} to spawn a chance of 1 to 3 per egg hatch
    -- emergency_egg_chance = 0.5, -- custom and should be handled in on_death
    -- mature_age = 150, -- custom, minimum age for which the entity should be at or above before reproducing
    -- is it land-borne (1), sea-borne (2), or amphibious (3) - default land-borne
    class = 1,
    -- movement
    springiness=0,
    buoyancy = 1.01,
    max_speed = 1,					-- m/s
    jump_height = 1,				-- nodes/meters
    view_range = 1,					-- nodes/meters
    -- attack
    attack={range=0.3, damage_groups={fleshy=1}},
    armor_groups = {fleshy=100},
    -- interactions (should be defined prior to registered animal code)
    predators = animals.get_interactors(name,"predators"),
    prey = animals.get_interactors(name,"prey"),
    rivals = animals.get_interactors(name,"rivals"),
    friends = animals.get_interactors(name,"friends"),
    -- other forms of interactions (should be defined in animal registration)
    predator_interactions = {
      default = 0.05 -- fight chance (95% flee chance)
      -- can specify specific predators such as "animals:darkasthaan = 0.5"
    },
    capture_interactions = {
      -- capture chance
      -- uses item group to determine capture possibility
      -- hand = 0.75, -- interactions with empty hand
      --club = { -- tool with club group
        -- allow for specification of a table for higher capture groups (if greater than the highest, will use highest)
        --[1] = 0.1,
        --[2] = 0.25,
        --[3] = 0.4,
      --},
    },
    -- mobkit functions
    on_step = mobkit.stepfunc,
    on_activate = mobkit.actfunc,
    get_staticdata = mobkit.statfunc,
    --logic = (function), -- must be defined in registration
    -- animations + sound + drops
    animation = {
      -- create animations for your animal
    },
    sounds = {
      -- create sounds for your animal
      -- use mobkit.make_sound(self,name) to play them
      punch = {
        name = "animals_punch",
        gain={0.5, 1.2},
        fade={0.5, 1.5},
        pitch={0.5, 1.5},
      },
    },
    --drops = {
      -- add drops for your animal upon death
    --},
    -- functions
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, fleshdmg) -- optional "fleshdmg" argument
      animals.on_punch(self, puncher, time_from_last_punch, tool_capabilities)
    end,
    on_rightclick = function(self, clicker)
      animals.stun_catch_mob(self, clicker, 0.75, true)
    end,
    -- custom
    --[[
    _on_death = function(self, pos)
      -- create a custom action to occur upon death
    end,
    --]]
    -- egg + spawnegg
    egg = {
      -- nodedef expectation
      description = "", --S('@1 Eggs'),
      tiles = {"animals_gundu_eggs.png"},
      stack_max = minimal.stack_max_medium,
      drawtype = "nodebox",
      paramtype = "light",
      node_box = {
        type = "fixed",
        fixed = {-0.08, -0.5, -0.08,  0.08, -0.4375, 0.08}, -- bug-sized egg
      },
      groups = {snappy = 3, falling_node = 1, dig_immediate = 3, flammable = 1, temp_pass = 1, edible = 1, egg = 1},
      sounds = animals.get_egg_sounds(),
      _hatching = { -- will become "hatching" instead of "_hatching" upon node definition
        -- should be either;
        -- string (only for 1 animal) e.g. = "animals:creature1"
        -- table (for more than 1 animal, provide names as indexes with a number specifying percentage)
        -- e.g. = {animals:creature1 = 0.5, animals:creature1_male = 0.5}
      },
      -- egg functions
      on_construct = function(pos,egg_data)
        local egg_timer = egg_data.egg_timer
        minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*2))
      end,
      -- _conditions_correct(pos)
      -- create a custom function that checks whether or not an egg should hatch
      -- return decimal for percentage chance
      -- should return true for if it can hatch
      -- return false if it cannot hatch and provide a new time to use or it'll default
      -- "new time" parameter can be made boolean true to prevent egg from hatching permanently
      --end,
      on_timer = function(pos, elapsed)
        local egg_timer = def.egg_timer
        if not type(egg_timer) == "number" then
          -- no hatching if egg_timer doesn't exist
          return false
        end
        local hatch = true
        local new_time
        -- if a custom _conditions_correct function was specified
        if type(def.egg._conditions_correct) == "function" then
          hatch, new_time = def.egg._conditions_correct(pos)
        end
        -- get a "time" to hatch by
        if new_time == true then
          -- you tell the egg to never hatch
          return false
        elseif type(new_time) == "number" then
          -- start new timer with given new_time
          minetest.get_node_timer(pos):start(new_time)
          return false
        end
        -- now for actual hatching (or other options)
        if hatch == true then
          -- try to hatch as according to hatch_egg
          return animals.hatch_egg(def,pos)
        elseif type(hatch) == "number" and hatch > 0 then
          -- random chance
          if random() <= hatch then
            return animals.hatch_egg(def,pos)
          end
        end
        -- continue to try to hatch, at another time
        return true
      end
    },
    spawnegg = {
      -- WILL ONLY ACCEPT THESE 3 PARAMTERS
      desc = "",
      inv_img = "",
      stack = 1,
    },
  }

  -- add values to def that weren't defined
  for defname,defvalue in pairs(basedef) do
    if def[defname] == nil then -- ignore "false"
      -- if not defined
      def[defname] = defvalue -- add to definition
    elseif type(defvalue) == "table" then
      local mod_deft = def[defname] -- modify_def_table
      if type(mod_deft) == "table" then
        -- iterate over the tables
        for dn2, dv2 in pairs(defvalue) do --defname2, defvalue2
          if mod_deft[dn2] == nil then
            mod_deft[dn2] = dv2
          end
        end
      else
        -- force as table
        def[defname] = defvalue
      end
    end
  end
  -- now to correct some values (or cause errors >:3)
  --assert(type(def.egg) == "table","defined 'egg' is not a table for nodedef, got '"..type(def.egg).."'")
  assert(type(def.spawnegg) == "table","defined 'spawnegg' is not a table for itemdef, got '"..type(def.spawnegg).."'")
  --assert(type(def.egg_timer) == "number","defined 'egg_timer' is not a number, got '"..type(def.egg_timer).."'")
  -- iterate over and adjust some values (if applicable)
  for defname,defvalue in pairs(def) do
    if (type(defvalue) == "string" and
      ( defname == "energy_egg" or
      defname == "mature_age" or
      defname == "lifespan" or
      defname == "oxygen_min") ) then
      -- allow for custom usage of adding, multiplying, dividing, or subtracting from a value via string
      defvalue = string.gsub(defvalue," ","") -- erase all spaces
      -- convert to table for a command system
      -- should be defined as so: "energy_max*5"
      -- reference a number and use proper index (will be CASE SENSITIVE)
      -- will NOT work with MULTIPLE arguments
      local data = {
        to_index = ""
      }
      for i = 1, string.len(defvalue) do
        local char = string.sub(defvalue,i,i)
        if (char == "*" or char == "+" or char == "-" or char == "/" or char == "^") then
          data.modifier = char
          data.number = string.sub(defvalue,(i + 1),string.len(defvalue))
          break
        else
          data.to_index = data.to_index..char
        end
      end
      data.number = tonumber(data.number)
      if not data.number then
        minetest.log("error","animals.register() could not parse '"..defname.."' as number for '"..name.."'. Using default.")
        def[defname] = basedef[defname]
      elseif (def[data.to_index] and type(def[data.to_index]) == "number") then
        local val = def[data.to_index]
        if data.modifier == "+" then
          val = val + data.number
        elseif data.modifier == "-" then
          val = val - data.number
        elseif data.modifier == "*" then
          val = val * data.number
        elseif data.modifier == "/" then
          val = val / data.number
        elseif data.modifier == "^" then
          val = val ^ data.number
        end
        def[defname] = val
      else
        minetest.log("error","animals.register() could not get '"..data.to_index.."' as number for modification for '"..defname.."' for animal '"..name.."'. Using default.")
        def[defname] = basedef[defname]
      end
    end
  end
  -- fix or issue errors about improperly set def.capture_interactions
  assert(type(def.capture_interactions) == "table","defined 'capture_interactions' is not a table, got '"..type(def.capture_interactions).."'")
  for defname,defvalue in pairs(def.capture_interactions) do
    if type(defvalue) == "number" then
      def.capture_interactions[defname] = {defvalue}
    elseif type(defvalue) == "string" then
      defvalue = tonumber(defvalue)
      if not defvalue then
        minetest.log("error","defined animal capture group index 'capture_interactions."..tostring(defname).."' got invalid percentage value (got string that could not be tonumber()'d)")
        def.capture_interactions[defname] = nil
      else
        defvalue = math.ceil(defvalue)
        def.capture_interactions[defname] = {defvalue}
      end
    elseif (type(defvalue) == "table") then
      for dn2, dv2 in pairs(defvalue) do --defname2, defvalue2
        if type(dn2) ~= "number" then
          local dn2temp = tonumber(dn2) -- temporary value
          if not dn2temp then
            error("defined animal capture group index 'capture_interactions."..tostring(defname).."."..tostring(dn2).."' is not a number, got '"..type(dn2).."'")
          else
            -- replace index with a numbered one
            defvalue[dn2] = nil
            dn2 = dn2temp -- set for next if statement
            defvalue[dn2temp] = dv2
          end
        end
        if type(dv2) ~= "number" then
          -- convert to number or nil (get rid of index)
          defvalue[dn2] = tonumber(dv2)
        end
      end
      if #defvalue == 0 then
        -- remove empty tables
        def.capture_interactions[defname] = nil
      end
    else
      error("defined animal capture group 'capture_interactions."..tostring(defname).."' is not a number or table of numbers, got "..type(defvalue).."'")
    end
  end
  -- set values for excessively harmful temps
  if type(def.killer_min_temp) ~= "number" then
    def.killer_min_temp = (def.min_temp - 7)
  end
  if type(def.killer_max_temp) ~= "number" then
    def.killer_max_temp = (def.max_temp + 25)
  end
  if type(def.burn_max_temp) ~= "number" then
    def.burn_max_temp = (def.killer_max_temp + 55)
  end
  if type(def.absolute_death_temp) ~= "number" then
    def.absolute_death_temp = (def.burn_max_temp + 300)
  end
  -- add reference points to initial_properties inside of the entity
  def.max_hp = def.initial_properties.max_hp
  def.visual_size = def.initial_properties.visual_size
  def.collisionbox = def.initial_properties.collisionbox
  -- modify functions for event changes or necessary actions
  local on_punch = def.on_punch
  def.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
    local multiplier = tool_capabilities.full_punch_interval or 0.1
    multiplier = math_clamp(time_from_last_punch / multiplier, 0, 1)
    local fleshdmg = tool_capabilities.damage_groups.fleshy or 1
    if not minimal.player_in_creative(puncher) then
      -- allow players in creative to infinitely hit
      fleshdmg = math.floor(fleshdmg * multiplier)
    end
    if fleshdmg <= 0 then
      return
    end
    self.last_punched = get_time(self.last_punched)
    if type(on_punch) == "function" then
      on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, fleshdmg)
    end
  end
  local on_rightclick = def.on_rightclick
  def.on_rightclick = function(self, clicker)
    local tool = clicker:get_wielded_item()
    local tooldef = tool:get_definition() 
    local tool_capabilities = tooldef.tool_capabilities
    local time_from_last_click = get_time(animals.rclick_times[clicker])
    animals.rclick_times[clicker] = get_time()
    if type(on_rightclick) == "function" then
      on_rightclick(self, clicker, time_from_last_click, tool_capabilities)
    end
  end
  local egg_data = {} -- use this to permit proper override of on_construct (returns intended variable properly)
  -- modify _conditions_correct to return egg data
  if def.egg then
    if type(def.egg._conditions_correct) == "function" then
      local _cc = def.egg._conditions_correct
      def.egg._conditions_correct = function(pos)
        if not pos then
          return false
        end
        return _cc(pos,egg_data)
      end
    end
    local on_construct = def.egg.on_construct
    def.egg.on_construct = function(pos)
      return on_construct(pos,egg_data)
    end
  end
  -- egg definition and correction
  if type(def.egg) ~= "table" or not def.egg.name then
    def.egg = nil
  elseif (type(def.egg._hatching) ~= "string" and type(def.egg._hatching) ~= "table") then
    --minetest.log("error","animals.register() has '"..def.name.."' egg definition, but no _hatching, removing egg definition.")
    --def.egg = nil
    def.egg._hatching = {[def.name] = 1}
  else
    if type(def.egg._hatching) == "string" then
      def.egg._hatching = {[def.egg._hatching] = 1}
    end
  end

  -- spawnegg definition and correction
  if type(def.spawnegg.stack) ~= "number" then
    def.spawnegg.stack = def.spawnegg.stack_max
    -- force number
    if type(def.spawnegg.stack) ~= "number" then
      def.spawnegg.stack = 1
    end
  end
  if type(def.spawnegg.desc) ~= "string" then
    def.spawnegg.desc = def.spawnegg.description
    if type(def.spawnegg.desc) ~= "string" then
      def.spawnegg.desc = tostring(def.spawnegg.desc)
    end
  end
  if (def.spawnegg.inv_img == "" or type(def.spawnegg.inv_img) ~= "string") then
    def.spawnegg.inv_img = def.spawnegg.inventory_image
    if (def.spawnegg.inv_img == "" or type(def.spawnegg.inv_img) ~= "string") then
      def.spawnegg.inv_img = "animals_carcass.png"
    end
  end

  -- simplify egg table
  local egg_ref
  if def.egg then
    minetest.register_node(def.egg.name,def.egg)
    --egg_ref = minetest.registered_nodes[def.egg.name]
  end
  egg_data = {
    energy_egg = def.energy_egg,
    egg_timer = def.egg_timer,
    young_per_egg = def.young_per_egg,
    ref = def.egg,
  }
  --[[
  def.egg = {
    name = def.egg.name,
    ref = egg_ref,
    hatching = def.egg._hatching,
    energy_egg = def.energy_egg,
    egg_timer = def.egg_timer,
    young_per_egg = def.young_per_egg,
  }
  --]]
  -- spawnegg
  animals.register_egg(minimal.merge_tables(egg_data,{name = def.name, drops = def.drops}) -- use a modified "def.egg" table
    ,def.spawnegg.desc,def.spawnegg.inv_img,def.spawnegg.stack)--def.spawnegg)
  -- creature
  minetest.register_entity(name,def)
  return def
end
