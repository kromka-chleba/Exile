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

local dsp_time = 3 -- despawn time
local max_objects = 30 -- how many registered animals can be in a certain radius
local mo_check_radius = 40 -- maxobject check radius

animals = animals
mobkit = mobkit

local S = animals.S

local use_vh1 = minetest.get_modpath("visual_harm_1ndicators")
if use_vh1 then
    VH1 = VH1
end

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
-- allows optional "since" value, expected number,
--  returns it subtracted by got time

function animals.get_time(since)
    local c_time = minetest.get_gametime() -- current_time
    return (type(since) == "number" and c_time - since or c_time)
end
-- local alias
local function get_time(...)
    return animals.get_time(...)
end


--flee sound (has to be in water!)
local function flee_sound(self)
    if not self.isinliquid then
        return
    end
    animals.make_sound(self,'flee','scared')
end

-- animals.make_sound
-- based off of mobkit.make_sound
-- can have a list of strings or tables to use if one or the other does not exist
-- will be prioritized from first parameter to last provided
-- sound1, sound2, sound3 (if sound1 doesn't exist, then sound2, and so on)
function animals.make_sound(self,...)
    if not self.object then return end
    if not self.sounds then return end
    -- allow for list of "alternative" sounds to be checked for
    local names = {...}
    local spec
    -- iterate over provided names
    for i=1,#names do
        -- accept strings or custom tables if they have a "name" index
        spec = type(names[i]) == "table" and names[i] or self.sounds[names[i]]
        -- pick random sound if it's a spec for random sounds
        spec = type(spec) == "table" and #spec > 0 and spec[random(#spec)] or spec
        -- table, and has a name? WE GOT IT!!!
        if type(spec) == "table" and type(spec.name) == "string" then
            break
        else -- clear out so we're not using a bad spec
            spec = nil
        end
    end
    if not spec then return end -- couldn't get a valid spec, can't play!
    spec = table.copy(spec)
    spec.object = self.object
    -- permit randomized ranges for values
    local function in_range(value)
        return type(value) == 'table' and value[1]+random()*(value[2]-value[1]) or value
    end
    spec.gain = in_range(spec.gain)
    spec.fade = in_range(spec.fade)
    spec.pitch = in_range(spec.pitch)
    spec.max_hear_distance = in_range(spec.max_hear_distance)
    -- play and return sound ID
    return minetest.sound_play(spec.name, spec)
end

-- return the luaentity + object of a provided userdata if possible into a table
function animals.get_structure(obj)
    local obj_t = {} -- obj_table
    if minetest.is_player(obj) then
        return {
            ent = {max_hp = minetest.PLAYER_MAX_HP_DEFAULT,
                   hp = obj:get_hp(),
                   memory = {},
                   object = obj
            },
            object = obj,
            player = true
        }
    end
    if (type(obj) == "userdata" and obj["get_luaentity"]) then
        -- get luaentity table and its object
        obj_t.ent = obj:get_luaentity()
        if not obj_t.ent then
            return
        end
        obj_t.object = obj_t.ent.object
        return obj_t
    end
    if (type(obj) == "table" and type(obj.object) == "userdata") then
        -- get "luaentity" (hopefully) and its object
        obj_t.ent = obj
        obj_t.object = obj_t.ent.object
        return obj_t
    end
    return
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

-- "sizeify" function
-- meant to scale an animal's collision box and visual size
-- "perc" is how much percentage to modify by
-- "base" boolean used for determining whether to calculate from defined stats (true) or local ones (false)
-- without "base", changes will be accumulative
-- with "base", will do percentage from registered_entities's index of initial_properties
function animals.sizeify(self, perc, base)
    if not (type(self) == "table" or type(self) == "userdata") then return end
    base = type(base) == "boolean" and base or false
    perc = type(perc) == "number" and perc or nil
    -- perc cannot be 1 if we're NOT calculating from base value
    -- if we're calculating from base value then we assume we're resetting if it's 1
    perc = base and perc or perc ~= 1 and perc or nil
    if not perc then return end
    -- get init_props from registered_entity if calculating from base
    -- allows for resetting or modifying upon base collisionbox and visual_size instead of accumulative
    local init_props = base and minetest.registered_entities[self.name] or nil
    init_props = init_props and init_props.initial_properties
    init_props = init_props and table.copy(init_props) or nil -- copy gotten props as to not modify overall table
    -- we're in runtime, prefer modifying the object instead of overall self table
    if type(self.object) == "userdata" then
        self = self.object
    end
    -- add percentage to provided table (collisionbox, visual_size only)
    local function add_perc(tb)
        if type(tb) ~= "table" then return tb end
        -- look for numbers inside of
        for index,value in pairs(tb) do
          -- only modify said value if a number
          if type(value) == "number" then
            tb[index] = value*perc
          end
        end
        -- return now modified table
        return tb
    end
    -- object perspective
    if type(self) == "userdata" then
        init_props = init_props or base == false and self:get_properties() or nil
        if not init_props then return end
        init_props.collisionbox = add_perc(init_props.collisionbox)
        init_props.visual_size = add_perc(init_props.visual_size)
        self:set_properties(init_props)
  -- expected self table (before runtime)
    else
        init_props = init_props or base == false and self.initial_properties or nil
        if not init_props then return end
        init_props.collisionbox = add_perc(init_props.collisionbox)
        init_props.visual_size = add_perc(init_props.visual_size)
    end
end

--------------------------------------------------------------------------
-- node interactions
--------------------------------------------------------------------------

local function node_drawtype(pos)
    if not (type(pos) == "table") then
        return {}
    end
    -- if pos is a pos, get node, otherwise assume pos is a node table
    local node = (pos.x and pos.y and pos.z
                  and minetest.get_node_or_nil(pos)) or pos
    -- purify invalid node table by turning it into an empty table
    node = type(node) ~= "table" or type(node.name) ~= "string" and {} or node
    -- get node information from registered_nodes or use purified node table
    node = node.name and minetest.registered_nodes[node.name] or node
    return node.drawtype, node
end
-- global usage
function animals.node_drawtype(...)
    return node_drawtype(...)
end

-- get a randomized position from mobkit's is_neighbor_node_reachable
--  by sending a string that's 1 to 8 or like so:
-- "12345678"
-- the mobkit function only accepts numbers from 1 to 8,
--  as it uses them to index a table
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
    -- get a random number from 1 to #numstring and then remove it from numstring
    -- gets a number for a position index in mobkit's reachable_node
    local length = string.len(numstring)

    local num = random(1,length)
    num = tonumber(string.sub(numstring,num,num)) -- got number
    numstring = string.gsub(numstring,tostring(num),"") -- erase from numstring
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

-- modify health of oneself
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

function animals.node_sound_egg_defaults(table)
    table = table or {}
    table.egg_hatch = {
        name = "animals_hatch_egg",
        gain = 0.8,
        max_hear_distance = 8
    }
    table = nodes_nature.node_sound_defaults(table)
    return table
end

--------------------------------------------------------------------------
-- Tracking
--------------------------------------------------------------------------

-- get distance between two targets
local function get_dist(targ1,targ2)
    local targ1_t = animals.get_structure(targ1)
    local targ2_t = animals.get_structure(targ2)
    local dist = math.huge
    if targ1_t and targ2_t then
        dist = vector.distance(targ1_t.object:get_pos(),targ2_t.object:get_pos())
    end
    return dist
end
-- get the closest target in a table to self,
-- third "maxdist" parameter for maximum distance entity can be
local function get_closest(self,targets,maxdist)
    if not targets then
        return
    end
    local closest = {}
    local cdist = type(maxdist) == "number" and maxdist or math.huge
    for index,targ in pairs(targets) do
        local dist = get_dist(self,targ)
        if dist < cdist then
            closest = {targ,index}
            cdist = dist
        end
    end
    return unpack(closest)
end

-- gets a list of entities in a distance to self
-- returns tables correlating to:
--  players, predators, prey, rivals, friends, or none
function animals.get_entities_in_distance(self,override)
    local entities = {
        predators = {},
        prey = {},
        rivals = {},
        friends = {},
    }
    local range = self.view_range or 1
    range = (type(override) == "number" and override or range)
    local players = {}
    local objs = self.nearby_objects
    --minetest.get_objects_inside_radius(mobkit.get_stand_pos(self),range)
    for _,obj in pairs(objs) do
        -- must be alive
        if mobkit.is_alive(obj) then
            local obj_structure = animals.get_structure(obj)
            if minetest.is_player(obj) then
                table.insert(players,obj)
            elseif obj_structure then
                -- not a player, find out what we can do with it
                for possinteract,interactable in pairs(entities) do
                    -- possibleinteractiontype, interact-table

                    -- iterate over possible interaction types
                    local interactors = animals.get_interactors(
                        self.name,possinteract)
                    if interactors then
                        -- self has this interaction type specified, look through
                        for _,inter_name in pairs(interactors) do
                            if inter_name == obj_structure.ent.name then
                                -- object has same name as an interactor specified
                                -- in specific interactiontype with self, add to table
                                table.insert(interactable,obj_structure.ent)
                            end
                        end
                    end

                end
            end
        end
    end
    entities.players = players -- add to entities
    return entities
end

-- day and night tracking, timeofday
function animals.timeofday(tod)
    local result = {}
    tod = type(tod) == "number" and tod or minetest.get_timeofday()
    -- calculations were eyeballed and thusly prone to change
    if tod <= 0.23 or tod >= 0.77 then
        result[1] = "night"
    else
        result[1] = "day"
    end
    -- during night
    if tod <= 0.06 then
        result[2] = "mid"
    elseif tod <= 0.2 then
        result[2] = "late"
    elseif tod <= 0.23 then -- should be ending for night (<=)
        result[2] = "dawn"
        -- during day
    elseif tod <= 0.43 then
        result[2] = "early"
    elseif tod <= 0.6 then
        result[2] = "mid"
    elseif tod <= 0.77 then
        result[2] = "late"
        -- during night
    elseif tod <= 0.81 then -- should be beginning for night (>=)
        result[2] = "dusk"
    elseif tod <= 0.94 then
        result[2] = "early"
    else
        result[2] = "mid"
    end
    result[3] = tod
    return unpack(result)
end

--------------------------------------------------------------------------
-- external mod support
--------------------------------------------------------------------------


local on_die_funcs = {}
local function on_die(self)
    for i = 1, #on_die_funcs do
        on_die_funcs[i](self.object)
    end
end
function animals.register_on_mob_die(func)
    table.insert(on_die_funcs, func)
end

--------------------------------------------------------------------------
--Life and death
--------------------------------------------------------------------------

----------------------------------------------------
-- drop on death what is defined in the entity table
function animals.handle_drops(self,despawn_time)
    on_die(self)

    if not self.drops then
        return
    end
    local timer = despawn_time or dsp_time -- how long until dead body despawns
    local dsp_pos = mobkit.get_stand_pos(self)
    -- despawn position (where the dead body is before despawn)
    if not dsp_pos then
        return
    end

    local function drops()
        for _,item in ipairs(self.drops) do
            local amount = random (item.min, item.max)
            local chance = random(1,100)

            if chance <= (100/item.chance) then
                -- ^= guarantees certainty if chance is 1 or 100 ( <= vs < )
                dsp_pos.y = dsp_pos.y+0.5
                item = item.name
                -- convert into string to avoid conflicts (and override)

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
                minetest.add_item(dsp_pos, item.." "..tostring(amount))
            end
        end
    end

    -- sometimes the function isn't ended properly for if condition before
    -- object removal, do not put any critical functions inside
    -- update_pos(). Function can end early before the if check can do the else
    local function update_pos()
        -- updates position in accordance to the dead body before despawn
        timer = timer - self.dtime
        local pos = mobkit.get_stand_pos(self)
        if pos and timer > 0 then
            dsp_pos = pos
        else
            return true
        end
    end
    -- do drops after specified despawn time
    minetest.after(dsp_time,function()
                       drops()
    end)
    mobkit.queue_high(self,update_pos,200)
end

-- animal death
function animals.hq_die(self)
    local despawn_time = self.despawn_time or dsp_time
    -- clear all priorities
    mobkit.clear_queue_high(self)
    mobkit.clear_queue_low(self)
    -- fallover
    self.logic = function(self) end      -- brain dead as well
    animals.handle_drops(self,despawn_time)
    mobkit.lq_fallover(self)
    minetest.after(despawn_time,function()
                       self.object:remove()
    end)
end

----------------------------------------------------
--core health
-- (meant for instantaneous effect checks)
-- (drowning/suffocation handled elsewhere)
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
            local multiplier = node.groups.fall_damage_add_percent
            -- used for fall damage calculation
            if (type(multiplier) == "number") then
                -- convert multiplier into a usable decimal
                multiplier = multiplier/100
                if (multiplier <= 0) then
                    -- if it's negative, make positive, and subtract it by 1 to get
                    -- the result of which velocity should be of itself (-70 = 0.3)
                    multiplier = -multiplier
                    multiplier = 1 - multiplier
                else
                    multiplier = 1 + multiplier
                end

                velocity_delta = floor(velocity_delta * multiplier)
            end

            if (drawtype == "airlike") then
                multiplier = 0
                -- lazily reuse multiplier to check if it's hitting entity or air
                local obj = minetest.get_objects_inside_radius(pos,1)
                -- look for an object nearby
                if obj and #obj > 0 then
                    obj = obj[random(1,#obj or 1)] -- lazily get one of em
                    obj = obj:get_luaentity()
                    if obj and obj.physical == true
                        and obj.collide_with_objects == true then
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
        local damage = floor(
            self.max_hp * min(1, velocity_delta/mobkit.terminal_velocity))

        animals.modify_hp(self,-damage)
    end
end



local function get_mean_temp(pos) -- this could be put somewhere else like in climate or minimal
    local temps = {}

    for x = -1, 1, 1 do -- create matrix of possible positions
        for y = -1, 1, 1 do
            for z = -1, 1, 1 do
                local npos = {x = (pos.x - x), y = (pos.y - y), z = (pos.z - z)}
                -- matrix the pos :D

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
    self.energy = self.energy or mobkit.recall(self,'energy') or 1
    self.age = self.age or mobkit.recall(self,'age') or 0

    self:modify('age',1)
    animals.vitals(self)
    --die from exhaustion, old age, no hp
    if self.energy <= 0 or self.age > self.lifespan or self.hp <= 0 then
        if type(self._on_death) == "function" then
            self._on_death(self, pos)
        end
        animals.hq_die(self)
        return false
    end

    if not self.conserve then
        self:modify('energy',-self.energy_loss)
    elseif (random() <= 0.005) then
        -- 0.5% chance to lose energy during energy conservation
        self:modify('energy',-self.energy_loss)
    end

    -- size difference mechanics, only call upon startup or nil size_dif
    if not self.size_dif then
        -- "base_size_dif" is a desired size from the usual adult size (say, an adult that grows to be smaller or larger)
        self.base_size_dif = self.base_size_dif or mobkit.recall(self,"base_size_dif") or nil
        -- current size_dif, modified by age_mechanics system
        self.size_dif = mobkit.recall(self,"size_dif") or self.base_size_dif
        -- clear out size_dif if it equals 1, ensure to remember this decision
        if self.size_dif == 1 then
            self:set("size_dif",nil,true)
        -- we're fine with this, custom size_dif
        elseif self.size_dif then
            animals.sizeify(self, self.size_dif)
            -- update stats according to size
            animals.size_dif_mechanics(self)
        end
        -- set to 1 and don't remember it if not specified or was 1
        self.size_dif = self.size_dif or 1
    end

    if self.age_mechanics then
        self:age_mechanics()
    end

    -- get temp
    local temp = climate.get_point_temp(pos, true)
    if (temp == 450) then
        -- get the mathematical "mean" of the pos and the surroundings nodes
        -- (workaround to torches)
        temp = get_mean_temp(pos)
    end

    --temperature stress
    local max_temp = self.max_temp
    local min_temp = self.min_temp

    if temp < min_temp or temp > max_temp then
        -- if this temperature is uncomfortable, try to find somewhere else!
        local killer_min_temp = self.killer_min_temp
        local killer_max_temp = self.killer_max_temp
        local burn_max_temp = self.burn_max_temp
        local absolute_death_temp = self.absolute_death_temp

        if (self.class ~= 2) then
            -- only for land creatures
            if (temp > killer_max_temp or temp < killer_min_temp) then
                -- clear all queues, you gotta get outta here! We dyin!
                mobkit.clear_queue_low(self)
                mobkit.clear_queue_high(self)
                animals.hq_roam_comfort_temp(self,90)
            else
                -- not as critical (uncomfortable, but not dying)
                animals.hq_roam_comfort_temp(self,42)
            end

            self.conserve = false -- moving around, thus not conserving energy
        end
        -- lose energy from discomfort
        self:modify('energy',-2)
        -- lose more energy dependent on temperature difference (discomfort also)
        if (temp > max_temp) then
            local mtp = (temp - max_temp)*0.05
            self:modify('energy',-mtp)
        elseif (temp < min_temp) then
            local mtp = (min_temp - temp)*0.02
            self:modify('energy',-mtp)
        end

        -- get really hurt or die from high temp
        if temp > killer_max_temp then
            -- use + instead of * to account for negative numbers
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
                self.energy = 0
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
        -- if not a fish out of water then (fish in water will heal up nicely :D)
        -- (oh and if temp is comfortable too)
        if animals.temp_comfy(self,temp) and not (not self.isinliquid and self.class == 2) then
            -- calculate cost
            local cost = math.random(5,10)
            cost = cost * (1 + (self.max_hp/self.hp) )
            -- increase cost depending on how harmed the creature is
            -- calculate w/ health efficiency
            local h_eff = self.heal_efficiency or 1
            cost = cost - (cost/20 * h_eff)
            -- cost subtracted by itself divided by 20 times heal_efficiency

            -- stabilize cost
            cost = math.round(cost*10)/10
            -- round second decimal point (7.52 --> 7.5)

            if cost < 0 then cost = 0 end -- do not go below 0
            if self.energy > cost*1.1 then -- could heal
                -- (chance = how much energy the creature has over the cost)
                if (random() >= cost/self.energy) then
                    animals.modify_hp(self,1)
                    self:modify('energy',-cost)
                end
            end
        end
    elseif (self.hp > self.max_hp) then
        -- this aint supposed to happen!
        self.object:set_hp(self.max_hp)
    end

    if (self.conserve == true) then
        mobkit.clear_queue_low(self)
        mobkit.animate(self,"dead")
    end

    -----------------
    --housekeeping
    --save energy, age, and other values if provided
    mobkit.remember(self,'age',self.age)
    mobkit.remember(self,'energy',self.energy)
    return true
end



----------------------------------------------------
-- place_egg, animals.place_egg
-- put an egg in the world, return true or nil on success or failure
-- returns false if can't get egg or too many of its kind are around
-- self, pos, medium, e_ov (energy_override)
-- medium can be string or table (if the node that the creature is in, can harbour an egg)
function animals.place_egg(self, pos, medium, e_ov)
    if type(self) ~= "table" then
        error("animals.place_egg: got invalid 'self' (expected table) for placing an egg, got type '"..type(self).."'")
    end
    -- ensure there exists an egg node to place
    local egg_data = self.egg_name or self.egg or self.name.."_eggs"
    egg_data = type(egg_data) == "string" and minetest.registered_nodes[egg_data]
        or type(egg_data) == "table" and egg_data
    if not egg_data then return end
    -- use first a medium override, otherwise check egg's required medium
    medium = (type(medium) == "string" and medium ~= "" and medium)
        or type(medium) == "table" and medium or nil
    medium = medium or egg_data.egg_medium or "air"
    -- get pos if no pos provided and round up pos
    pos = pos or mobkit.get_stand_pos(self)
    local p = mobkit.get_node_pos(pos)
    -- check if what we're about to lay an egg in is even a valid node
    local c_node = minetest.registered_nodes[minetest.get_node(p).name] -- current_node
    if not c_node then return end -- not a valid node, return
    -- work around to slabs and cobble not permitting egg lay
    if c_node.walkable then
      -- get collision box (for cobble) or node box (for slabs)
      local box = c_node.collision_box or c_node.drawtype == "nodebox" and c_node.node_box
      -- don't lay eggs on top of eggs
      if box and box.fixed and not (c_node.groups and c_node.groups.egg) then
        -- if not an array of boxes
        if type(box.fixed[1]) ~= "table" then
          -- check pos above
          p = minimal.pos_shift(p,{y=1})
          c_node = minetest.registered_nodes[minetest.get_node(p).name]
          if not c_node then return end
        end
      end
    end
    -- uses self's energy and energy_egg (with optional max_pop)
    local e_egg = self.energy_egg
    -- seek a "self.egg_name" or create an egg_name using the placer's name
    local max_pop = self.max_pop or max_objects

    -- remove male or baby identifier when checking names
    local check_name = string.gsub(self.name,"_male","")
    check_name = string.gsub(self.name,"_baby","")

    -- number of its kind in an area
    local objcount = #animals.get_entities_inside_radius(check_name,
                                                         pos, mo_check_radius)
    -- first check if we're overpopulated
    local can_lay = objcount <= max_pop
    -- check node for if it's a compatible medium now
    if can_lay then
        can_lay = false -- temporarily set can_lay to false (checking medium)
        -- convert to table for next functionality
        if type(medium) == "string" then
            medium = {medium}
        end
        -- allow multiple acceptable "mediums"
        for _,tag in pairs(medium) do
            -- verify if string
            tag = type(tag) == "string" and tag or nil
            if tag then
                -- check if node_name is equal to provided medium tag
                can_lay = c_node.name == tag
                -- allow group detection if layable area hasn't been found 
                if can_lay ~= true and tag:sub(1,6) == "group:" then
                    local group = c_node.groups and c_node.groups[tag:sub(7)]
                    can_lay = group and group > 0
                end
            end
            -- we verified we can lay an egg here, no more checking
            if can_lay then break end
        end
    end

    if can_lay then

        local posu = {x = p.x, y = p.y - 1, z = p.z}
        local n = mobkit.nodeatpos(posu)

        if n and n.walkable and n.name ~= "nodes_nature:tree_mark" then
            minetest.set_node(p, {name = egg_data.name})
            e_ov = e_ov or self.energy < e_egg and self.energy -- can't lay eggs lower than energy_egg properly
            if type(e_ov) == "number" and e_ov >= 15 then
                -- energy override noted, jot it down

                local meta = minetest.get_meta(pos)
                meta:set_float("energy_egg",e_ov)
                e_egg = e_ov
                -- set custom energy_egg
            end
            self:modify('energy',-e_egg)
            return true
        end

    end

end

-- place an egg during near or precise death (and die)

-- generic function to be utilized by any "emergency_egg" custom function
-- in animals' self
-- 'chance' override permitted for custom percentage from usual
function animals.emergency_egg(self, pos, medium, chance)
    local egg_chance = chance or self.emergency_egg_chance or 1

    local energy = self.energy
    if (type(energy) ~= "number" or energy < 15) then
        return false
    end

    if (random() < egg_chance) then
        -- lay egg and die if successful
        if animals.place_egg(self, pos, medium, energy) then
            self.energy = -1
            return true
        end
    end

    return false
end

----------------------------------------------------
-- get an amount of offspring to release
function animals.calculate_egg_young(self)
    local young_per_egg = self
    -- in case you just want to just pass the young_per_egg instead
    if (type(self) == "table" or type(self) == "userdata") then
        -- either use a found young_per_egg or self
        -- (assuming is young_per_egg table)
        young_per_egg = self.young_per_egg or young_per_egg
    end

    if (type(young_per_egg) == "table") then
        -- allow for randomized amount of young per egg
        if (type(young_per_egg[1]) == "number"
            and type(young_per_egg[2]) ~= "number") then
            -- if only one number provided, use that
            young_per_egg = {young_per_egg[1],young_per_egg[1]}
        elseif (type(young_per_egg[1]) ~= "number"
                and type(young_per_egg[2]) ~= "number") then
            return
        end
        young_per_egg = random(young_per_egg[1],young_per_egg[2])
    end

    return type(young_per_egg) == "number" and young_per_egg or nil
end

----------------------------------------------------
--release offspring from an egg (called from timers)
function animals.hatch_egg(pos, egg_data, medium, replace, spawn)
    -- egg_data, position
    -- CUSTOM OVERRIDES:
    --  medium (to spawn entities in - can be nil (will only check for air), string, or table),
    --  replace (replace with - can be nil),
    --  spawn (optional, but required if no egg_hatching in egg_data), can be string or a list of names
    egg_data = egg_data or minimal.get_nodedef(pos)
    -- destroy node if we can't get egg_data
    if type(egg_data) ~= "table" then
        minetest.set_node(pos, {name = "air"})
        return false
    end
    -- fix medium, replace
    medium = medium or egg_data.egg_medium
    medium = type(medium) == "table" and medium or {medium}
    -- purify medium table
    for tagi,tag in pairs(medium) do -- tag index, tag
      -- not a node, nuh-uh-uh!
      if not minetest.registered_nodes[tag] then
        -- don't delete if we were secretly a group check
        if tag:sub(1,6) ~= "group:" then
          medium[tagi] = nil
        end
      end
    end
    -- add "air" if medium table has no existing nodes
    if #medium == 0 then
      medium[1] = "air"
    end
    replace = replace or egg_data.egg_replace
    replace = minetest.registered_nodes[replace] or {name="air"}
    replace = replace.name

    -- removes egg
    local function destroy_egg()
      minetest.set_node(pos, {name = replace})
    end

    local suitable = minetest.find_nodes_in_area(
        {x=pos.x-1, y=pos.y-1, z=pos.z-1},
        {x=pos.x+1, y=pos.y+1, z=pos.z+1}, medium)
    --if can't find the stuff this mob moves through then it dies
    if #suitable < 1 then
        destroy_egg()
        return false
    end

    -- young per egg should be explicitly defined in egg_data
    local young_per_egg = animals.calculate_egg_young(egg_data)
    if not young_per_egg then
      destroy_egg()
      return false
    end

    -- get what to hatch into
    if type(spawn) ~= "string" and egg_data.egg_hatching then
        local hatching = egg_data.egg_hatching
        local sort_table = {}
        for h_name,h_perc in pairs(hatching) do -- hatch_name, hatch_percentage
            table.insert(sort_table,{h_perc,h_name})
        end
        -- spawn is made into a table and iterated over
        -- printing names as many times as young_per_egg
        if #sort_table == 1 then
            spawn = {}
            for i = 1, young_per_egg do
              spawn[i] = sort_table[1][2]
            end
        elseif #sort_table == 2 then
            if sort_table[2][1] > sort_table[1][1] then
                -- if last index has a greater percent chance,
                -- readd last index to first, remove old last index to beginning
                table.insert(sort_table,1,sort_table[2])
                table.remove(sort_table,3)
            end
            -- math.random() on largest percent first
            spawn = {}
            for i = 1, young_per_egg do
              if sort_table[1][1] >= math.random() then
                  spawn[i] = sort_table[1][2]
              else
                  spawn[i] = sort_table[2][2]
              end
            end
        elseif #sort_table > 2 then -- manually sort it so greatest is at the top, lowest at the bottom
            local hatching_table = {}
            for index,info in pairs(sort_table) do
                if #hatching_table <= 0 then
                    -- add first index
                    table.insert(hatching_table,info)
                else
                    -- check hatching_table find where to add the possible hatcher
                    local insert = {}
                    for h_index,h_info in pairs(hatching_table) do
                        -- if info has a greater percentage than certain index of
                        --  hatching_table, then add itself in an order behind
                        if info[1] > h_info[1] then
                            insert = {h_index - 1,info}
                            --table.insert(hatching_table,h_index - 1,info)
                        elseif h_index >= #hatching_table then
                            -- add to end of table due to not being bigger
                            --  than previous percentage
                            insert = {#hatching_table + 1,info}
                        end
                    end
                    table.insert(hatching_table,insert[1],insert[2])
                end
            end
            -- create a list
            spawn = {}
            for i = 1, young_per_egg do
                -- now iterate through hatching_table randomly to get a name
                for _,info in pairs(hatching_table) do
                    if info[1] >= math.random() then
                        spawn[i] = info[2]
                        break
                    end
                end
                -- last "else", get largest percent
                if not spawn[i] then
                    -- code smell until I figure out why having mixed unsorted
                    -- and set percentages for hatching causes index 1 to be index 0
                    spawn[i] = (hatching_table[1] and hatching_table[1][2])
                        or (hatching_table[0] and hatching_table[0][2])
                end
            end
        end
        -- if none of these if statements fit, then spawn is just a list of names, don't worry
    end

    -- only do spawning if we can spawn somethin'
    spawn = type(spawn) == "table" and spawn or type(spawn) == "string" and {spawn} or nil
    if not spawn then
      destroy_egg()
      return false
    end
    -- energy egg - how much energy is given to each spawned young
    local energy_egg = egg_data.energy_egg
    local meta = minetest.get_meta(pos):get_float("energy_egg")
    if (meta > young_per_egg) then
        energy_egg = meta
    end
    -- ensure is number and greater than young_per_egg
    -- energy_egg should explicitly be contained in egg_data
    energy_egg = energy_egg and energy_egg > young_per_egg and energy_egg or 100

    local objcounts = {} -- used to determine the counts of each defined creature
    local could_hatch = false
    for _,name in pairs(spawn) do
        local entity_data = minetest.registered_entities[name]
        assert(entity_data,"animals.hatch_egg: got '"..tostring(name)..
            "' to hatch, but it does not exist!")
        -- prioritize max_pop defined in egg_data
        -- otherwise entity_data, then base max_objects
        local max_pop = egg_data.max_pop or entity_data.max_pop or max_objects

        -- remove male or baby identifier when checking names
        local check_name = string.gsub(name,"_male","")
        check_name = string.gsub(name,"_baby","")

        -- get specified objcount from objcounts table (of check_name) or set a new one
        local objcount = objcounts[check_name] or #animals.get_entities_inside_radius(check_name, pos, mo_check_radius)

        local start_e = math.floor(energy_egg/young_per_egg) -- starting energy per each, start_energy
        -- only if less than or equal to current max population
        if objcount <= max_pop then
            could_hatch = true
            local ran_pos = suitable[random(#suitable)]
            ran_pos.y = ran_pos.y - (entity_data.initial_properties.collisionbox[2]
                                     + entity_data.initial_properties.collisionbox[5])
            local ent = minetest.add_entity(ran_pos, name)
            local sounds = egg_data.sounds
            if sounds and sounds.egg_hatch then
                local sound = table.copy(sounds.egg_hatch)
                sound.pos = pos
                minetest.sound_play(sound.name, sound)
            end
            -- spawn entity, apply starting energy
            ent = ent:get_luaentity()
            mobkit.remember(ent,'energy', start_e)
            mobkit.remember(ent,'age',0)
            objcount = objcount + 1
        -- let's not waste energy, give more energy to each new young (remove from young_per_egg)
        else
            young_per_egg = young_per_egg - 1
        end
        -- update object counts
        objcounts[check_name] = objcount
    end
    -- try hatching another time
    if not could_hatch then return true end

    destroy_egg()
    return false
end

--------------------------------------------------------------------------
--Movement
--------------------------------------------------------------------------



----------------------------------------------
--roam to places with equal or lesser darkness
function animals.hq_roam_dark(self,prty)
    local timer = time() + 30
    local func=function()
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

        if (mobkit.is_queue_empty_low(self) and self.isonground)
            or (prty >= 45 and self.isonground) then

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
                    numstring, h, tp, lf = get_reachable_node(self,numstring)
                    -- shortened versions of "height, tpos, liquidflag"

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

    local func = function()
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

                if (h and not lf) then
                    -- if height somethin' and if provided pos is not a liquid
                    local tempn = climate.get_point_temp(tp, true)
                    local temp_c,temp_s = animals.temp_comfy(self,tempn)
                    -- temp_comfy (is the provided pos a comfortable temp?),
                    --  temp_status (utilized to check whether too hot or too cold)

                    if (temp_s or temp_c == true) then
                        -- make sure the animal goes to best suitable temperature
                        local old_bt = best_temp -- old_best_temp - used for comparison
                        if (type(best_temp) ~= "number" or
                            (temp_s == "hot" and tempn < best_temp
                             and tempn > min_temp) or
                            (temp_s == "cold" and tempn > best_temp
                             and tempn < max_temp)
                            -- prevent creatures running into fires to
                            --  warm themselves
                        ) then
                            -- if a best_temp wasn' specified or a better temperature
                            --  was found for seeking comfy temperatures
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
                            -- if a good pos can't be found, the above if statement
                            -- mess will determine the most optimal area to go
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

    local func=function()

        if time() > timer then
            return true
        end

        if mobkit.is_queue_empty_low(self) and self.isonground then
            local neighbor = random(8)

            local height, tpos, liquidflag =
                mobkit.is_neighbor_node_reachable(self, neighbor)

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

            local height, tpos, liquidflag =
                mobkit.is_neighbor_node_reachable(self, neighbor)

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

                local nodeapp = true
                -- node appropriate -- if node should be walked to
                for _,group in pairs(iggroups) do
                    if (minetest.get_item_group(n_node,group) > 0) then
                        -- if node is in a group that is to be ignored...
                        nodeapp = false
                        break
                    end
                end
                if (nodeapp == false) then
                    -- found a node to be ignored oop, don't walk to it
                    return true
                end
                for _,group in pairs(groups) do
                    if (minetest.get_item_group(n_node,group) > 0) then
                        -- if node is in a specified group then...
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
                if ((nodeu and nodeu.drawtype == 'liquid')
                    or (noded and noded.drawtype == 'liquid')) then

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
    local func = function()

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

    local func = function()

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

    local func = function()
        if time() > timer then
            return true
        end

        if not mobkit.is_alive(tgtobj) then return true end

        if mobkit.is_queue_empty_low(self) and self.isonground then
            local pos = mobkit.get_stand_pos(self)
            local opos = tgtobj:get_pos()
            if vector.distance(pos,opos) > 3 then
                animals.make_sound(self,'warn')
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

    local func = function()
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
function animals.on_punch(self, puncher, time_from_last_punch,
                          tool_capabilities, dir, dmg)
    if not mobkit.is_alive(self) then
        -- oops I'm dead
        animals.make_sound(self,"punch_death",'punch')
        return
    end
    dmg = (type(dmg) == "number" and dmg or 0)
    -- do damage
    animals.make_sound(self,'punch')
    animals.modify_hp(self,-dmg)

    local conserve = mobkit.recall(self,'conserve')
    if (self.hp < self.max_hp/10 or self.hp <= (dmg * 2)
        or conserve == true) then
        animals.make_sound(self,'scared','warn')
        animals.fight_or_flight(self, puncher, nil, 0)
    else
        animals.fight_or_flight(self, puncher, 75)
        -- being attacked is a high priority!
    end
end

-- warn function, give that encroaching enemy a warning!
function animals.hq_warn(self, threat, prty)
    local tgtspec = animals.get_structure(threat)
    if not tgtspec then
        return
    end
    local timer=0
    local tgttime=0
    local init = true
    local warn_timer = self.warning_timer or 12
    local func = function(self)
        if not mobkit.is_alive(threat) then return true end
        if init then
            mobkit.animate(self,'stand')
            init = false
        end

        local dist = get_dist(self,tgtspec.object)

        if dist > self.warn_distance then -- originally 11
            -- out of worry
            return true
        elseif dist < self.aggression_distance
            or timer >= warn_timer then
            -- too close man (aggro dist was originally 4)

            mobkit.remember(self,'hate',tgtspec.object:get_player_name())
            animals.hq_attack_eat(self, prty+10, tgtspec.object) -- priority
        else
            timer = timer+self.dtime
            if mobkit.is_queue_empty_low(self) then
                mobkit.lq_turn2pos(self,tgtspec.object:get_pos())
            end
            -- make noise in random intervals
            if timer > tgttime then
                animals.make_sound(self,'warn')
                tgttime = timer + 1.1 + random()*1.5
            end
        end
    end
    mobkit.queue_high(self,func,prty)
end

-- runfrom, flee from target
function animals.hq_runfrom(self,prty,tgtobj,notscared)
    local run_timer = self.runfrom_timer
        or notscared and (self.runfrom_break_timer or 10) or 20
    local exclaim_timer = 4
    local range = minetest.is_player(tgtobj) and self.player_warn_distance
        or animals.is_interactor(
            self,'predators',tgtobj) and self.predator_warn_distance
        or animals.is_interactor(
            self,'rivals',tgtobj)
        and self.territorial_warn_distance or self.warn_distance
    if not notscared then animals.make_sound(self,'scared','warn') end

    local func = function(self)
        if not mobkit.is_alive(tgtobj) then return true end
        run_timer = run_timer - self.dtime
        if not notscared then
            exclaim_timer = exclaim_timer - self.dtime
        end
        if run_timer <= 0 then
            return true
        end
        if exclaim_timer <= 0 then
            animals.make_sound(self,'scared','warn')
            exclaim_timer = random(37,70)/10
        end
        local dist = get_dist(self,tgtobj)
        if dist <= self.warn_distance and not notscared then
            run_timer = run_timer + random(1,5)/10
            -- random chance of 0.1 to 0.5 second addition
            if dist <= self.aggression_distance then
                -- HOLY CLOSE, RUN!!!
                run_timer = run_timer + random(2,4) -- 2 to 4 second addition
            end
        end

        if mobkit.is_queue_empty_low(self) and self.isonground then
            local pos = mobkit.get_stand_pos(self)
            local opos = tgtobj:get_pos()
            if dist < range then
                local tpos = {x=2*pos.x - opos.x,
                              y=opos.y,
                              z=2*pos.z - opos.z}
                mobkit.goto_next_waypoint(self,tpos)
            else
                self.object:set_velocity({x=0,y=0,z=0})
                return true
            end
        end
    end
    mobkit.queue_high(self,func,prty)
end

--attack or run vs entity or player
function animals.fight_or_flight(self, threat, prty, chance)
    mobkit.clear_queue_high(self)
    prty = type(prty) == "number" and prty or 55
    if type(chance) ~= "number" then
        if minetest.is_player(threat) then
            chance = self.player_interaction
        else
            -- get stable values
            threat = animals.get_structure(threat)
            if not threat then
                return
            end
            threat = threat.ent
        end
        local pred_itr = self.predator_interactions
        if pred_itr and pred_itr[threat.name] and not chance then
            chance = pred_itr[threat.name] or pred_itr.default
        end
        if not chance then
            chance = 0.5
        end
        -- custom rival interaction
        if animals.is_interactor(self,"rivals",threat) then
            if (threat.hp <= self.hp * 0.8) then
                -- if enemy's health is lower than 80% of own health
                --  then higher chance of attacking back
                chance = chance * 1.3 * (1+(self.hp*0.8/threat.hp)/50)
                -- 30% more base chance with a small addition of extra chance
                --  depending on health difference
            else
                chance = chance * 0.3 -- 70% less chance
            end
        end
    end
    --fight chance, or run away
    -- (+against players as well, there was a notice about attacking players
    --  that are attached, maybe fixed?)
    -- run away from players in creative or attached to something
    if random()<chance and
        not (minetest.is_player(threat) and threat:get_attach()
             or minimal.player_in_creative(threat)) then
        -- fight!
        if self.class == 2 then
            mobkit.hq_aqua_attack(self, prty, threat.object
                                  or threat, self.max_speed)
        else
            animals.hq_warn(self, threat, prty)
        end
    else
        -- flight!
        mobkit.animate(self,'fast')
        if self.class == 2 then
            animals.hq_swimfrom(self, 55, minetest.is_player(threat) and threat
                                or threat.object, self.max_speed)
            flee_sound(self)
        else
            animals.hq_runfrom(self,prty, minetest.is_player(threat) and threat
                               or threat.object)
        end
        --mobkit.animate(self,'fast')
        --mobkit.make_sound(self,'scared')
    end
end

----------------------------------------------------------------
--Find and Flee predators
function animals.predator_avoid(self, prty, chance)
    local pred_table = self.predators or
        animals.get_interactors(self.name,"predators")
    if not pred_table then
        -- end lookout due to no possible predators to find
        minetest.log("error",self.name..
                     ": has no predators defined but tried to escape from one")
        return
    end
    prty = type(prty) == "number" and prty or 55

    pred_table = animals.get_entities_in_distance(self).predators
    if #pred_table <= 0 then
        -- no predators, safe to proceed
        return
    end
    local pred_itr = self.predator_interactions -- predator_interact
    for  _,_ in ipairs(pred_table) do
        local pred, pred_index = get_closest(self,pred_table,
                                             self.warn_distance or self.view_range)
        if not pred then
            table.remove(pred_table, pred_index)
        else
            chance = type(chance) == "number" and chance
                or pred_itr and (pred_itr[pred.name]
                                 or pred_itr.default) or 0
            animals.fight_or_flight(self, pred, prty, chance)
            return pred
        end
    end
end

----------------------------------------------------------------
--Find and hunt prey
function animals.prey_hunt(self, prty)
    local function condition(targs)
        local targ, targ_index = get_closest(self,targs)
        if not targ or not targ.object then
            table.remove(targs,targ_index)
            return
        end
        local tgtpos = targ.object:get_pos()
        local drawtype = node_drawtype(tgtpos)
        if drawtype == "liquid" and self.hp >= self.max_hp and
            (self.oxygen_min and self.oxygen > self.oxygen_min) then
            -- look for a solid node underneath (safe to hunt)
            -- custom hunting_depth to check how far down this solid node has to be
            --  and if meant to hunt prey that's in water
            tgtpos = minimal.pos_shift(tgtpos,{y = -(self.hunting_depth or 1)})
            drawtype = node_drawtype(tgtpos)
        end
        if (drawtype ~= "liquid") then
            animals.hq_attack_eat(self,prty,targ,true)
            return true
        end
        -- failed to get a proper target, remove from table
        table.remove(targs,targ_index)
    end
    local function aqua_condition(targs)
        local targ, targ_index = get_closest(self,targs)
        if not targ or not targ.object then
            table.remove(targs,targ_index)
            return
        end
        local tgtpos = targ.object:get_pos()
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
            animals.hq_aqua_attack_eat(self, prty, targ.object, self.max_speed)
            return true
        end
        table.remove(targs,targ_index)
    end

    prty = type(prty) == "number" and prty or 25
    local prey_table = self.prey or animals.get_interactors(self.name,"prey")
    if not prey_table then
        -- end search due to no possible prey to find
        minetest.log("error",self.name..
                     ": has no prey defined but tried to hunt prey")
        return true
    end
    prey_table = animals.get_entities_in_distance(self).prey
    if #prey_table <= 0 then
        -- no prey, end search
        return false
    end
    -- return true if we get a prey
    for _,_ in pairs(prey_table) do
        if (self.class == 2) then
            if aqua_condition(prey_table) then
                return true
            end
        else
            if condition(prey_table) then
                return true
            end
        end
    end
end



----------------------------------------------------
-- sediment eating functions

-- modifies the provided sediment at pos
local function eat_sediment(pos,nodedef,grassy)
    -- scratching up surface layers
    nodedef = type(nodedef) == "string" and nodedef
        or type(nodedef) == "table" and nodedef.name
    nodedef = minetest.registered_nodes[nodedef]
    if not nodedef then return end

    -- we're only modifying the sediment if it's grassy
    if (minetest.get_item_group(nodedef.name,"spreading") > 0
        and grassy == true) then
        -- it's a grass, let's eat it and modify it
        -- (and if eating grass was desired)
        local sediment_name = nodedef._wet_salty_name
        -- use this to get the raw sediment
        -- (grassy _wet_salty variations of sediments do not exist)
        local dugdef -- for sediment being converted back into regular soil
        if sediment_name then
            sediment_name = sediment_name:gsub("_wet_salty","") -- get raw soil name
            dugdef = minetest.registered_nodes[sediment_name]
        end
        if dugdef and nodedef.name:match("_wet") then -- check if original is wet
            dugdef = minetest.registered_nodes[dugdef._wet_name]
        end
        if dugdef then
            -- check slope
            local slope = nodedef.name:match('slope')
                and (nodedef.name:match('inner') and 'inner_'
                     or nodedef.name:match('outer') and 'outer_'
                     or nodedef.name:match('pike') and 'pike_' or '')
                or nil
            slope = slope and "slope_"..slope or nil
            if slope then
                -- set mod_origin:slope_name
                -- remove old mod_origin to allow for easier editing
                sediment_name = dugdef.mod_origin..":"..slope
                    ..dugdef.name:gsub(dugdef.mod_origin..":","")
            end
            slope = minetest.registered_nodes[sediment_name]
            dugdef = slope or dugdef
            -- don't error on an improper slope, default to old dugdef if
            --  there's issues
        end
        if dugdef then -- if we got a node, set it
            -- set the non-spreading version of the node
            minetest.set_node(pos, {name = dugdef.name})
        end
    end

    minetest.check_for_falling(pos)
    -- allow custom consumption sound for sediments
    local eating_sound = nodedef.sounds and nodedef.sounds.consumed
    -- no point to copying a table we already created if the sound doesn't exist
    eating_sound = eating_sound and table.copy(eating_sound) or {
        name="nodes_nature_dig_crumbly",gain=0.2,max_hear_distance=10
                                                                }
    eating_sound.pos = pos
    minetest.sound_play(eating_sound.name,eating_sound)
end

--for things that eat sediment (i.e. dig in the mud)
function animals.eat_sediment_under(pos, chance)
    local p = mobkit.get_node_pos(pos)
    local posu = {x = p.x, y = p.y - 1, z = p.z}
    local under = minetest.get_node(posu).name

    if minetest.get_item_group(under, "sediment") > 0 then
        -- CONSUME
        if random()< chance then
            -- scratch up that sediment!
            eat_sediment(posu,under)
        end

        return true
    else
        return false
    end
end

-- eat grassy nodes with a chance of modifying the grass node to its
--  non-grassy self (does not respect naturalslopes)
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
-- hurt targeted creature
function animals.hurt_target(self,target,consume)
    local targ_specs = animals.get_structure(target)
    if not self or not targ_specs then
        return
    end
    local tflp = get_time(self.did_last_punch) -- time from last punch
    local ent = targ_specs.ent
    local ent_hp = ent.hp
    local ent_mhp = ent.max_hp
    if not ent_hp or not ent_mhp then
        return
    end
    target:punch(self.object,tflp,self.attack)
    if targ_specs.player then
        ent.hp = targ_specs.object:get_hp()
    end
    self.did_last_punch = get_time()
    local dmg = (ent_hp - ent.hp) -- health subtracted after punch

    consume = type(consume) == "boolean" and consume or consume ~= false and true
    -- consume targeted creature
    if consume and dmg > 0 then
        dmg = math_clamp(dmg,0,ent_mhp)
        -- prevent accidental excessive energy gain by clamping below max_hp

        -- eat bits of opponent
        local ent_e = (ent.energy or 1)
        local energytake = (ent_e * (dmg / ent_mhp) ) -- omnomnom
        if targ_specs.player then
            energytake = (200*dmg)
        end

        self:modify('energy',energytake*.25) -- take 25%
        ent.energy = ent_e - energytake
        -- make opponent lose energy (use old way due to players)

        if (ent.hp <= dmg) then
            self:modify('energy',energytake*.75)
            -- add 75% of opponent's energy for nomming fully
            if not targ_specs.player then
                ent.object:remove()
            end
        end
    end
    return ent.hp <= dmg -- either continues (false) or ends attack (true)
end

-- checks if target is within Y of collisionbox + range,
--  distance within range + positive collisionbox X
-- then does a raycast to see if it can hit
function animals.target_in_range(self,tgt)
    tgt = animals.get_structure(tgt)
    if not tgt then
        return false
    end
    local range = (self.attack and self.attack.range
                   or 0.1) + ((self.stepheight or 0) * 1.1)
    local pos = self.object:get_pos()
    local tpos = tgt.object:get_pos()
    local selfbox = self.object:get_properties().collisionbox
    local tgtbox = tgt.object:get_properties().collisionbox
    if tpos.y >= (pos.y + (selfbox[2] - range))
        and tpos.y <= (pos.y + selfbox[5] + range) then

        tpos.y = pos.y
    else
        return false
    end
    if vector.distance(pos,tpos) > (range+selfbox[4]) then
        return false
    end
    local tpos2 = vector.add(tpos,vector.multiply(vector.direction(pos,tpos),3))
    pos = minimal.shift_pos(pos,{y=selfbox[2]})
    for pointed_thing in minetest.raycast(pos,tpos2) do
        if pointed_thing.ref == tgt.object then
            return true
        end
    end
    return false
end

----------------------------------------------------------------
--like mobkit version, but including removal of prey and gaining energy
--to hit is to catch... for predators, where the chewing does the killing
function animals.hq_aqua_attack_eat(self,prty,tgtobj,speed,eat)
    local timer = time() + (type(self.aggression_timer) == "number"
                            and self.aggression_timer or 12)

    local tgt = animals.get_structure(tgtobj)
    if not tgt then
        return
    end

    if type(eat) ~= "boolean" then
        eat = minetest.is_player(tgtobj) and self.consume_players == true

            or self.consume_players ~= false and self.predators
            and self.predators[tgt.name] and self.consume_predators == true

            or self.consume_predators ~= false and self.rivals
            and self.rivals[tgt.name] and self.consume_rivals == true

            or self.consume_rivals ~= false and self.consume_non_prey ~= false
        -- will be true if consume_non_prey is not specified
    end

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
            animals.make_sound(self,'attack','bite')
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
            if tpos.y>pos.y+0.5 then
                self.object:set_velocity({x=vel.x,y=vel.y+0.5,z=vel.z})
            elseif tpos.y<pos.y-0.5 then
                self.object:set_velocity({x=vel.x,y=vel.y-0.5,z=vel.z})
            end
        end
        if animals.target_in_range(self,tgt) then -- bite
            animals.make_sound(self,'bite','attack')
            mobkit.hq_aqua_turn(self,prty,yaw-pi,speed)
            return animals.hurt_target(self,tgtobj,eat)
        end
        mobkit.go_forward_horizontal(self,speed)
    end
    mobkit.queue_high(self,func,prty)
end





---------------------------------------------------
--like mobkit version, but including removal of prey and gaining energy
--to hit is to catch... for predators, where the chewing does the killing
local function lq_jumpattack_eat(self,height,target,consume)
    local phase=1
    local tgtbox = target:get_properties().collisionbox

    local func=function()
        if not mobkit.is_alive(target) then return true end

        if phase == 1 and self.isonground then
            -- collision bug workaround
            local vel = self.object:get_velocity()
            vel.y = -mobkit.gravity*sqrt(height*2/-mobkit.gravity)
            self.object:set_velocity(vel)
            animals.make_sound(self,'charge')
            phase=2
        elseif phase==2 then
            local dir = minetest.yaw_to_dir(self.object:get_yaw())
            local vy = self.object:get_velocity().y
            dir=vector.multiply(dir,6)
            dir.y=vy
            self.object:set_velocity(dir)
            phase=3
        elseif phase==3 then      -- in air
            local tgtpos = target:get_pos()
            local pos = self.object:get_pos()

            local dist = vector.distance(tgtpos,pos)

            -- calculate attack spot
            local yaw = self.object:get_yaw()
            local dir = minetest.yaw_to_dir(yaw)
            local apos = mobkit.pos_translate2d(pos,yaw,self.attack.range)

            if animals.target_in_range(self,target) then -- bite
                -- bounce off
                local vy = self.object:get_velocity().y
                self.object:set_velocity({x=dir.x*-3,y=vy,z=dir.z*-3})
                -- play attack sound if defined
                animals.make_sound(self,'attack','bite')
                phase=4

                -- eat bits of opponent
                return animals.hurt_target(self,target,consume)
            else
                return true
            end
        else
            return true
        end
    end
    mobkit.queue_low(self,func)
end



function animals.hq_attack_eat(self,prty,tgt,eat)
    local t = time()
    local timer = time() + (type(self.aggression_timer) == "number"
                            and self.aggression_timer or 12)
    local attack_range = self.attack.range or 0.5

    tgt = animals.get_structure(tgt)
    if not tgt then return end
    local tgtobj = tgt.object
    tgt = tgt.ent
    if type(eat) ~= "boolean" then
        eat = minetest.is_player(tgtobj) and self.consume_players == true

            or self.consume_players ~= false and self.predators
            and self.predators[tgt.name] and self.consume_predators == true

            or self.consume_predators ~= false and self.rivals
            and self.rivals[tgt.name] and self.consume_rivals == true

            or self.consume_rivals ~= false and self.consume_non_prey ~= false
        -- will be true if consume_non_prey is not specified
    end
    local func = function(self)
        if time() > timer then
            if not animals.is_interactor(self,"prey",tgt.name) then
                -- we've done enough, get away from them now
                animals.hq_runfrom(self, prty-4, tgtobj, true)
            else
                mobkit.hq_roam(self,15)
            end
            return true
        end
        if not mobkit.is_alive(tgtobj) then return true end
        if self.oxygen < (self.oxygen_min or self.lung_capacity*0.9) then return true end

        if mobkit.is_queue_empty_low(self) then
            local pos = mobkit.get_stand_pos(self)
            local tpos = mobkit.get_stand_pos(tgtobj)
            local dist = vector.distance(pos,tpos)
            mobkit.lq_turn2pos(self,tpos)
            local height = tgt.height or 0
            height = tgtobj:is_player() and 0.35 or height*0.6
            if dist <= attack_range * 6 and abs(pos.y - tpos.y) <= 3 then
                -- close in
                lq_jumpattack_eat(self,height,tgtobj, eat)
                if dist <= math.min(attack_range * 3,self.view_range) then
                    -- add 0.5 to 1.75 seconds to timer if enemy or prey
                    --  is still in close distance
                    timer = timer + random(2,7)*0.25
                    if animals.is_interactor(self,"prey",tgt.name) then
                        -- add more time if prey (0.5 to 1.5 seconds)
                        timer = timer + random(2,6)
                    end
                end
            else
                if dist > self.view_range then
                    -- out of sight, out of mind
                    return true
                end
                mobkit.lq_dumbwalk(
                    self,mobkit.pos_shift(tpos,{x=random(-20,20)/10,
                                                z=random(-20,20)/10}))
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
function animals.territorial(self, eat, chance_multiplier)

    for  _, riv in ipairs(self.rivals) do

        local rival = mobkit.get_closest_entity(self, riv)

        if rival then
            local range = self.territorial_warn_distance or self.warn_distance
            --flee if hurt
            if self.hp < self.max_hp/4 then
                mobkit.animate(self,'fast')
                if self.class ~= 2 then
                    animals.make_sound(self,'scared','warn')
                    animals.hq_runfrom(self, 25, rival)
                else
                    flee_sound(self)
                    animals.hq_swimfrom(self, 25, rival ,self.max_speed)
                end
                return true
            elseif not mobkit.is_alive(rival)
                or (get_dist(self,rival) < range) then

                return true
            end

            --contest! The more energetic one wins
            local r_ent = rival:get_luaentity()
            local r_ent_e = r_ent.energy or 0
            local r_hp = rival:get_hp()
            local dom_chance = 0
            if self.energy >= r_ent_e then
                dom_chance = 0.8
                if (self.energy - (self.energy_max*0.025)) > r_ent_e then
                    -- 2.5% of own energy_max
                    -- overwhelming amount of energy
                    dom_chance = 1
                end
            elseif self.energy >= (r_ent_e - (self.energy_max*0.013)) then
                dom_chance = 0.5
            elseif self.energy >= (r_ent_e - (self.energy_max*0.025)) then
                dom_chance = 0.4
            end
            if r_hp >= (self.max_hp*2) then
                -- negative
                dom_chance = dom_chance * 0.05
            elseif self.hp > r_hp then
                -- positive
                dom_chance = dom_chance * (self.hp/r_hp)
            end
            dom_chance = type(chance_multiplier) == "number"
                and dom_chance * chance_multiplier or dom_chance
            dom_chance = dom_chance * math.min(1.1*(self.hp/self.max_hp),1)
            -- chance determined by amount of health left of max_hp

            if self.class == 2 then flee_sound(self) end
            if random() <= dom_chance then
                if eat then -- consume
                    if self.class ~= 2 then
                        animals.hq_attack_eat(self, 25, rival)
                    else
                        animals.hq_aqua_attack_eat(self, 25, rival, self.max_speed)
                    end
                else -- harass
                    mobkit.animate(self,'fast')
                    if self.class ~= 2 then
                        animals.make_sound(self,'warn')
                        mobkit.hq_chaseafter(self,25,rival)
                    else
                        animals.hq_swimafter(self, 15, rival, self.max_speed)
                    end
                end
                return true
            else -- run from
                mobkit.animate(self,'fast')
                if self.class ~= 2 then
                    animals.make_sound(self,'scared','warn')
                    animals.hq_runfrom(self,25,rival)
                else
                    animals.hq_swimfrom(self, 25, rival ,self.max_speed)
                end
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

    local func = function()
        if time() > timer then
            return true
        end

        if not mobkit.is_alive(tgtobj) then return true end

        if mobkit.is_queue_empty_low(self) then
            local pos = mobkit.get_stand_pos(self)
            local tpos = mobkit.get_stand_pos(tgtobj)
            local dist = vector.distance(pos,tpos)
            if dist <= min_dist or abs(tpos.y - pos.y) >= 5 then
                if random()<0.3 then
                    mobkit.lq_idle(self,1)
                else
                    mobkit.hq_roam(self,prty)
                end
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

    local func = function()
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
            animals.make_sound(self,'call')
            return true
        end

    end
    mobkit.queue_high(self,func,prty)
end







function animals.flock(self, prty, min_dist, herding_dist, aqua_speed)
    min_dist = min_dist or self.view_range
    herding_dist = herding_dist or self.herding_dist
        or self.herding_distance or min_dist * 0.25

    for  _, fr in ipairs(self.friends) do

        --local friend = mobkit.get_closest_entity(self, fr)
        local friend =mobkit.get_nearby_entity(self, fr)

        if friend and get_dist(self, friend) <= min_dist then
            --get distance, if too far away go to them
            if aqua_speed then
                mobkit.animate(self,'walk')
                animals.make_sound(self,'call')
                animals.hq_flock_water(self, prty, friend, herding_dist, aqua_speed)
            else
                mobkit.animate(self,'walk')
                animals.make_sound(self,'call')
                animals.hq_flock(self, prty, friend, herding_dist)
            end
            return true
        end
    end

end

----------------------------------------------------------------
--mate
--go after them, if close enough do the deed
function animals.hq_mate(self,prty,tgtobj)
    local timer = time() + 10

    local func = function()
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
                animals.make_sound(self,'mating','call')
                if self.sex == "male" then
                    --get the other one pregnant
                    tgtobj:set('pregnant',true,true)
                else
                    --get pregnant
                    self:set('pregnant',true,true)
                end
                self.sexual = false
                return true
            else
                animals.make_sound(self,'call')
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
        local sexy = (self.sexual and ent.sexual) and self.sex ~= ent.sex
        local preg = (self.sex == "female" and self or ent).pregnant or false
        if sexy == true and preg == false then
            return ent
        end
    end
    return false
end

function animals.get_entities_inside_radius(creature,pos,radius,match_string)
    radius = (type(radius) == "number" and radius or 30)
    -- will use string.match if true
    if (type(match_string) ~= "boolean") then
        match_string = true
    end
    -- if provided creature is an entity or objectref
    if (type(creature) == "userdata") then
        if (type(creature["get_luaentity"]) == "function") then
            creature = creature:get_luaentity()
        end
        if (type(creature) ~= "nil" and type(creature) ~= "boolean"
            and type(creature) ~= "string") then
            creature = creature["name"]
        else
            creature = ""
        end
    end

    creature = (type(creature) == "string" and creature or "*")
    if (type(pos) ~= "table") then
        return
    end
    if (type(pos.x) ~= "number" or type(pos.y) ~= "number"
        or type(pos.z) ~= "number") then
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
            if (name == creature or creature == "*"
                or (match_string == true and string.match(creature,name))) then
                aobjs[#aobjs + 1] = v
            end
        end
    end

    return aobjs
end



-- Animals Interactors Interactions
animals.interactors = {}
function animals.add_interactors(creature, itype, ...)
    -- creature to be set with properties, interactiontype, list of creatures

    -- adds the minetest luaentity names of creatures to a
    --  certain interaction type provided by a specified creature

    -- for example, animals.add_interactors("animals:pegasun","rivals", "animals:sneachan")
    -- would add the entity 'animals:sneachan' to the rivals of "animals:pegasun"
    -- "self" can be used to add oneself instead of repeating name as so:
    -- animals.add_interactors("animals:pegasun","rivals", "self")

    -- control "autoassign" can be determined as true or false at end of "..." list (default true)
    -- will add counterparts to a specified interactiontype
    -- so if you specify a creature as a pred to yours, it will add yours as a prey to said creature
    -- setting it false will prevent this autoassign

    -- lowercase strings for easier finding and indexing
    if type(creature) == "table" then
        -- get "name" of said table
        creature = creature.name
    end
    assert(type(creature) == "string",
        "animals.add_interactors: could not get valid name from creature (not a string or table with .name string). Got '"..
        tostring(creature).."' type "..type(creature))
    -- we only work lowercase
    creature = creature:lower()

    assert(type(itype) == "string",
        "animals.add_interactors: attempt to add inapplicable itype (non-string) for '"..creature
        .."'. Got '"..tostring(itype).."' type "..type(itype))
    itype = itype:lower()

    local entity = minetest.registered_entities[creature]
    -- utilized for searching and override

    local interactable = animals.interactors[creature]
    -- finds the creature's table provided within animals.interactors
    if (type(interactable) ~= "table") then -- creates new one if not found
        animals.interactors[creature] = {}
        interactable = animals.interactors[creature]
    end

    -- interaction table
    -- finds the specified interactiontype table within creature's table
    local itable = animals.interactors[creature][itype]

    -- check for itable in entity (if registered already) or create a new interactiontype
    --  table if not found
    if (type(itable) ~= "table") then
        -- check if entity exists, and check if it has the interactiontype
        if entity then
            itable = entity[itype]
            -- if itype exists, copy it for local modifications and set it in the
            -- global interactors table under said itype
            if itable then
                itable = table.copy(itable) -- pass a copy
                animals.interactors[creature][itype] = itable
            end
        end
        -- create new table with the interactiontype if it could not get one
        --  from the registered entity (or if there wasn't a entity with said name)
        if not itable then
            itable = {}
            animals.interactors[creature][itype] = itable
        end
    end

    -- possible creatures
    -- convert specified creatures into an easily accessible table
    --  (the ... for multiple args)
    local posscreatures = {...}
    -- autoassign:
    -- if you add a creature as a rival, it will add yours as a rival to the creature
    -- if you add a creature as a pred, it will add yours as a prey to the creature
    -- only works for prey/predators, friends/rivals, no other strings will be sought inverted
    local autoassign = true
    -- autoassign can be specified at the end of a list, will be removed from the table
    if type(posscreatures[#posscreatures]) == "boolean" then
        autoassign = posscreatures[#posscreatures]
        posscreatures[#posscreatures] = nil
    end
    for _,interactor in ipairs(posscreatures) do
        -- unpacks table and adds to posscreatures
        if type(interactor) == "table" then
            for _,readd in pairs(interactor) do
                table.insert(posscreatures,readd)
            end
        end
        -- name of said creature
        if (type(interactor) == "string") then
            -- allow simplification with "self" parameter
            if interactor == "self" then
                interactor = creature
            end
            -- add said creature as an "interactor" within the provided
            --  interactiontype (if specified creature is an entity name)
            itable[#itable + 1] = interactor
            -- autoassign described above (we also don't want to autoassign ourselves lol)
            if autoassign and creature ~= interactor then
                -- only apply to interaction types that have a counterpart
                -- counterpart interaction type
                local c_itype = itype == "predators" and "prey" or itype == "prey" and "predators" or
                    (itype == "rivals" or itype == "friends") and itype or nil
                if c_itype then
                    -- if doesn't exist yet, create an empty table to loop over
                    local c_itable = animals.get_interactors(interactor, c_itype) or {}
                    -- check if we were already added to prevent duplication (by looping over table)
                    -- counterpart added
                    local c_added = false
                    for _, existing in ipairs(c_itable) do
                        -- created true and break if found
                        c_added = creature == existing
                        if c_added then break end
                    end
                    -- add ourselves as an interactor
                    if not c_added then
                        -- set autoassign to false to prevent stack overflow
                        animals.add_interactors(interactor, c_itype, creature, false)
                    end
                end
            end
        end
    end
    -- will override entity's interaction type with the provided animals
    if entity then -- #TODO: luacheck warning:
        -- Indirectly setting read-only field 'registered_entities.?.?' of global 'minetest'
        entity[itype] = itable
    end

    return true
end

function animals.get_interactors(creature,itype)
    -- creature to get stats from, interationtype

    -- get a table of the creatures that interact with the
    --  specified creature in the specified interactiontype way

    -- get name of table if table
    creature = type(creature) == "table" and creature.name or creature
    assert(type(creature) == "string",
        "animals.get_interactors: could not get valid name from creature (not a string or table with .name string). Got '"..
        tostring(creature).."' type "..type(creature))
    -- we only work lowercase
    creature = creature:lower()

    assert(type(itype) == "string",
        "animals.get_interactors: attempt to get inapplicable itype (non-string) for '"..creature
        .."'. Got '"..tostring(itype).."' type "..type(itype))
    itype = itype:lower()

    -- get the creature's interactors table
    local interactable = animals.interactors[creature]
    if type(interactable) ~= "table" then
        -- add an option to get a creature table and if it gets a creature,
        --  set it for interactions
        interactable = minetest.registered_entities[creature]
        if not interactable then
            return
        else
            interactable = {}
            animals.interactors[creature] = interactable
        end
    end
    -- get who the creature interacts in what specified way
    local itable = interactable[itype]
    if not itable then
        -- get the interaction table directly from the entity if defined properly
        local entity = minetest.registered_entities[creature]
        if entity then
            itable = entity[itype]
            -- if it got an interaction table, add it to the creature
            if itable then
                interactable[itype] = itable
            end
        end
    end
    -- return nil (no table found) or the specified table of interaction type
    return itable
end

-- is_interactor
function animals.is_interactor(creature,itype,target)
    -- creature to get stats from, interaction type, target

    -- returns true if provided target is of the interaction type

    local interactors = animals.get_interactors(creature,itype)
    if interactors then
        if type(target) ~= "string" and type(target) == "table"
            or type(target) == "userdata" then

            target = target.name
        end
        if type(target) == "string" then
            target = string.lower(target)
            for _,targname in pairs(interactors) do
                if targname == target then
                    return true
                end
            end
        end
    end
    return false
end

-------- Mobkit function rewrites

-- makes it so animals do not see or interact with the player
-- (if the animals use this instead of mobkit's) if player is in creative

function animals.get_nearby_player(self,forceplyr)
    -- "forceplyr" bool parameter to force a player despite creative mode
    local plyr = mobkit.get_nearby_player(self) -- get player from mobkit
    if plyr then
        if forceplyr then return plyr end
        -- if player, then check if player is NOT in creative...
        if (not minimal.player_in_creative(plyr)) then
            if get_dist(self,plyr) >= (self.player_warn_distance
                                       or self.warn_distance) then
                return
            end
            return plyr
        end
    end
end

-- animals.size_dif_mechanics
-- modifies max_hp, speed, attack, and capture mechanics depending on self.size_dif
-- does not modify actual animal's physical object - see animals.sizeify for that
function animals.size_dif_mechanics(self)
    local dif = self.size_dif
    if not dif then return end
    if not self.object then return end -- we don't even have a physical body!!!
    local data = minetest.registered_entities[self.name]
    if not data then return end
    self.max_speed = data.max_speed * dif
    local max_hp = data.initial_properties and data.initial_properties.max_hp
    local attack = data.attack
    local cap_interact = data.capture_interactions
    -- checks
    if max_hp then
        -- round down max_hp after multiplying it by dif, ensure it's no less than 1
        -- smaller have less hp, bigger have more hp
        max_hp = math.max(math.floor(max_hp*dif), 1)
        local props = self.object:get_properties()
        -- if got object properties, update them to new max_hp (if max_hp does not equal object max_hp)
        if props and max_hp ~= props.max_hp then
            props.max_hp = max_hp
            self.object:set_properties(props)
        end
        -- set self values
        self.max_hp = max_hp
        -- if current hp is greater than new max_hp, clamp down or leave it as is
        self.hp = self.hp > max_hp and max_hp or self.hp
    end
    if attack then
        -- reset to data attack values
        if dif == 1 then
            self.attack = attack
        else
            -- copy for local modifications
            attack = table.copy(attack)
            attack.range = attack.range*dif -- increase/decrease range depending on size dif (smaller less bigger more)
            -- copy damage_groups or create blank table (won't be iterated over)
            attack.damage_groups = attack.damage_groups and table.copy(attack.damage_groups) or {}
            for dmgtype, dmg in pairs(attack.damage_groups) do
                -- increase/decrease each damage according to size dif
                attack.damage_groups[dmgtype] = math.max(math.floor(dmg*dif),1)
            end
            -- update attack
            self.attack = attack
        end
    end
    if cap_interact then
        -- reset to data capture interactions
        if dif == 1 then
            self.capture_interactions = cap_interact
        else
            -- copy for local modifications (don't want to modify global table!)
            cap_interact = table.copy(cap_interact)
            for captype, capvalue in pairs(cap_interact) do -- capture type, capture value (percentage/table)
                if type(capvalue) == "table" then
                    -- again, copy for local modifications
                    capvalue = table.copy(capvalue)
                    for ind,caperc in pairs(capvalue) do -- index, capture percentage
                      -- clamp below or equal to 1 with math.min
                      -- divide capvalue by difference to get higher chance for smaller sizes, lower chance for bigger
                        capvalue[ind] = math.min(caperc / dif, 1)
                    end
                    cap_interact[captype] = capvalue
                end
            end
            -- update
            self.capture_interactions = cap_interact
        end
    end
end

-- animals.age_mechanics
-- modifies animal size (sizeify) and "size_dif" (size difference) value according to age
-- determines with "growth phases", base_size_dif (base size difference), and a min_size (minimum size)
function animals.age_mechanics(self)
    -- not ready to grow, return
    if self.growth_next_age and self.age < self.growth_next_age then return end
    -- get or create a "mature_age" to base age_mechanics off of
    local mature_age = self.mature_age or (self.lifespan * 0.12)
    -- we're a big kid now, no more modifications !
    if self.age >= mature_age and not self.growth_next_age then
        return
    end
    -- some helpful variables
    local size = self.base_size_def or 1 -- expected base size dif for adult (expected usual, permit custom)
    local min_size = self.growth_min_size or 0.25 -- can't be smaller than 25%
    local phases = self.growth_phases or 6 -- allow phases override, otherwise 6
    -- PHASE;;
    -- get phase by interpolating using age divided by (mature_age divided by phases), rounding the result,
    -- and ensuring it's not under 1 (has to be 1 or over)
    -- determine requirement for first phase with mature_age/phases
    -- divide age by first phase requirement to determine how much over for phases
    -- e.g. a mature_age of 1200 would be divided by 6 for 200
    -- an age of 300 divided by 200 would be 1.5, rounded down to 1 for phase 1
    -- an age of 430 divided by 200 would be 2.15, rounded down to 2 for phase 2
    local phase = math.max(math.floor(self.age/(mature_age/phases)),1)
    -- DIF;;
    -- determine size difference based on phase, while limiting between min_size and base size dif
    -- using BEDMAS, subtract size by min_size to get a smaller limited number to multiply-
    -- by the percentage made from phase divided by phases
    -- finally, add min_size as a base to the value
    -- e.g. if min_size is 0.25, base size 1, and if there are 6 total phases
    -- then the first phase size difference will be 0.375
    -- size-min_size would be 0.75, which is then multiplied by phase/phases (1/6 making 0.16666)
    -- which would be 0.75 times 0.16666 : 0.125
    -- which then has min_size added to as a base: 0.25 + 0.125 for 0.375
    local dif = min_size+(size-min_size)*(phase/phases)
    -- growth_next_age;;
    -- predict age for next phase (current phase + 1)
    -- predict by dividing next phase by total phases for a percentage, then multiply mature_age by such
    -- CLEAR OUT growth_next_age if current phase is going to be greater than or equal to total phases
    self.growth_next_age = phase < phases and mature_age*((phase+1)/phases) or nil
    self.growth_current_phase = phase -- add self value for growth_current_phase
    -- we're already this size, no updating!
    if self.size_dif == dif then return end
    self:set('size_dif',dif,true) -- set internal "size_dif" value for memory
    animals.sizeify(self, dif, true) -- update physically to new size (use base size)
    animals.size_dif_mechanics(self) -- update stats to new size
    return true
end

-- Taken directly from mobkit to properly calculate drowning
function animals.vitals(self)

    -- vitals: oxygen
    if self.lung_capacity then
        local colbox = self.object:get_properties().collisionbox
        local lowpos = mobkit.pos_shift(self.object:get_pos(),{y=colbox[5]})
        local drawtype = node_drawtype(lowpos) -- node at hitbox top
        local drawtype_above = node_drawtype(minimal.pos_shift(lowpos,{y=1}))

        -- override self.isinliquid from mobkit to account for overhead water
        self.isinliquid = self.isinliquid or drawtype_above == "liquid" or false
        -- do after above calculation for hunting_depth if specified
        drawtype_above = self.hunting_depth and node_drawtype(minimal.pos_shift(lowpos,{y=self.hunting_depth})) or drawtype_above

        local oxygen_min = self.oxygen_min or self.lung_capacity
        local breathing_rate = self.breating_rate or 1
        -- utilized by non-water animals
        -- determines whether or not the animal should try to get out
        --  (if there's too much water)
        local dangerous = false
        if (node_drawtype(mobkit.pos_shift(lowpos,{y=-(self.hunting_depth or 1)})) == "liquid"
            or drawtype_above == "liquid"
            or oxygen_min == self.lung_capacity) then
            dangerous = true
        end

        if (self.class ~= 2 and self.class ~= 3) then
            if drawtype == 'liquid' then
                self.oxygen = math_clamp(self.oxygen - 0.5,0,self.lung_capacity)
                if (self.oxygen <= oxygen_min
                    or dangerous == true) then -- if uncomfortable, swim to shore
                    animals.hq_liquid_recovery(self,70) -- LIQUID RECOVERY
                    -- (if on ground) and if there's potential air, gasp for air!!!
                    -- (doesn't work due to the timing of when vitals is ran - every sec)
                    --if self.isonground and drawtype_above ~= "liquid" then
                        --mobkit.lq_dumbjump(self,0.9)
                    --end
                end
            else
                self.oxygen = math_clamp(self.oxygen + breathing_rate, 0,
                                         self.lung_capacity)
            end
        elseif (self.class ~= 3) then
            if self.isinliquid then
                self.oxygen = math_clamp(self.oxygen + breathing_rate, 0,
                                         self.lung_capacity)
            else
                self.oxygen = math_clamp(self.oxygen - 0.5, 0, self.lung_capacity)
            end
        end
        if (self.class == 3 and self.oxygen < self.lung_capacity) then
            -- amphibians get to breathe wherever they wanna
            self.oxygen = math_clamp(self.oxygen + breathing_rate, 0,
                                     self.lung_capacity)
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
    local n_s -- no surface (could not find a surface)
    --local goto_pos
    local old_pos
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
        -- looking around now
        yaw=yaw+(pi*0.25)
        -- couldn't find a node in immediate vicinity, increase scanning radius
        if radius < self.view_range and yaw>2*pi then
            radius = radius + 1
        end
        -- no surfaces to go to could be found, we're going rambo
        if n_s then
            -- move_chance, always try to move if radius equals view_range, or on a 80% of radius/view_range chance
            -- set to 0 if we don't have to do this
            -- higher chances if radius is getting closer to view_range
            local m_c = (radius >= self.view_range and 1.01 or radius > 1
                and (radius/self.view_range) * .8) or nil
            -- random chance
            if m_c and m_c > random() then
                --pos2 = minimal.pos_shift(pos2,{y=-1})
                local height, liquidflag = mobkit.get_terrain_height(pos2)
                -- isn't water, let's wing it!
                if not liquidflag then
                    mobkit.lq_turn2pos(self, pos2)
                    mobkit.lq_dumbwalk(self, pos2, 2)
                    radius = 1 -- reset search radius
                end
            end
            -- try jumping if stuck in one position
            if old_pos and vector.distance(pos, old_pos) < 0.05 then
              mobkit.clear_queue_low(self) -- clear all other low level tasks to prioritize jumping
              -- 20% chance of just forcing us to technically be "on the ground"
              self.isonground = random() < 0.2 and true or self.isonground
              mobkit.lq_dumbjump(self, 2)
            end
            -- continuously update for above calculation
            old_pos = pos
      -- no surface in reach can be ascertained, try to find one instead
      elseif radius >= self.view_range or node_drawtype(minimal.shift_pos(pos,{y=1})) ~= "liquid" then
            radius = 1 -- reset radius
            n_s = true
        end
    end
    mobkit.queue_high(self,func,prty)
end



-- REGISTRATION FUNCTIONS

-- animals.register_egg
-- animal is only required if you do NOT specify the following
--  things in your egg def:

-- name, egg_hatching, energy_egg, egg_time, and young_per_egg
-- if you have the above specified, then you may proceed without error

function animals.register_egg(def, animal)
    assert(type(def) == "table",
           "animals.register_egg: provided egg definition is not a table!")
    local name = def.name or (animal and animal.name.."_eggs") or nil
    assert(type(name) == "string",
           "animals.register_egg: was not provided a string for name, got '"
           ..type(name).."'")
    if animal and type(animal) ~= "table" then
        error("animals.register_egg: was given an 'animal' argument that "..
              "was invalid, nil or table only, got '"..type(animal).."'")
    end
    -- fix name properly
    name = name:sub(1,1) == ":" and minetest.get_current_modname()..name or
        not name:match(":") and minetest.get_current_modname()..":"..name or name



    def.description = def.description or (animal and animal._desc and S("@1 Eggs",animal._desc)) or name
    def.tiles = def.tiles or {"animals_gundu_eggs.png"}
    def.stack_max = def.stack_max or minimal.stack_max_medium
    def.drawtype = def.drawtype or "nodebox"
    if def.drawtype == "nodebox" then
        def.node_box = def.node_box or
            {
                type = "fixed",
                fixed = {-0.08, -0.5, -0.08,  0.08, -0.4375, 0.08}, -- bug-sized egg
            }
    end
    def.paramtype = def.paramtype or "light"

    def.groups = def.groups or {}
    def.groups.egg = def.groups.egg or 1
    def.groups.snappy = def.groups.snappy or 3
    def.groups.falling_node = def.groups.falling_node or 1
    def.groups.dig_immediate = def.groups.dig_immediate or 3
    def.groups.flammable = def.groups.flammable or 1
    def.groups.temp_pass = def.groups.temp_pass or 1
    def.groups.edible = def.groups.edible or 1
    def.sounds = def.sounds or {}
    def.sounds = animals.node_sound_egg_defaults(def.sounds)
    -- custom egg data
    def.egg_hatching = def.egg_hatching or (animal and animal.name)
    -- new feature: autocreate percentages if not provided
    if type(def.egg_hatching) == "table" then
        -- purely string indexes do not count for table length
        -- account for if there is a 1 number index and 1 stringed index
        local numbered_indexes = #def.egg_hatching
        -- more than 1 egg_hatching index, set to true,
        --  obviously we can calculate this
        local do_hatch_calculation = numbered_indexes > 1 and true or false
        -- false to start otherwise

        -- we got only 1 numbered index,
        --  check if there is a string index and verify hatch calculation
        if numbered_indexes == 1 then
            for index,_ in pairs(def.egg_hatching) do
                if type(index) == "string" then
                    do_hatch_calculation = true
                    break
                end
            end
        end
        -- verified that we should do this hatch calculation
        if do_hatch_calculation then
            local percent = 0
            -- iterates through properly assessed percentages
            -- and calculates unproperly assessed percentages in correlation
            for spawn_animal,set_percent in pairs(def.egg_hatching) do
                -- only if spawn_animal is string, and correlated
                --  percentage is a number
                if type(spawn_animal) == "string" and type(set_percent) == "number" then
                    -- add found percentage to compounding percentage
                    percent = percent + set_percent
                end
            end
            -- if total calculated collected percentage is below 1 then
            -- continue (because we aren't aiming for 110% or more!)
            if percent < 1 then
                percent = 1-percent -- will be 1 if percent is 0
                percent = percent/#def.egg_hatching
                -- percentage divided by total amount of numbered indexes

                -- only iterate through number indexes
                for i=1,#def.egg_hatching do
                    -- get (expected and assumed) animal name string from numbered index
                    local spawn_animal = def.egg_hatching[i]
                    -- provide animal name as index, apply percentage
                    def.egg_hatching[spawn_animal] = percent
                    -- remove old numbered index
                    def.egg_hatching[i] = nil
                end
                -- error right now instead of purifying or erroring later lol
            else
                error("animals.register_egg: egg_hatching collected percentage "..
                      "is too great to calculate unsorted percentages! "..
                      (percent*100).."%")
            end
            -- why did you just do only one...
        elseif numbered_indexes == 1 then
            -- assume it's a string
            def.egg_hatching = {[def.egg_hatching[1]] = 1}
        end
    end
    assert(def.egg_hatching,"animals.register_egg: could not get hatching or "..
           "name for egg hatching mechanics")
    def.egg_hatching = type(def.egg_hatching) == "table" and def.egg_hatching
        or {[def.egg_hatching] = 1}

    def.energy_egg = def.energy_egg or (animal and animal.energy_egg)
    assert(def.energy_egg,"animals.register_egg: could not get energy_egg for "
           ..name)
    def.egg_time = def.egg_time or (animal and animal.egg_time)
    assert(def.egg_time,"animals.register_egg: could not get egg_time for "..name)
    def.young_per_egg = def.young_per_egg or (animal and animal.young_per_egg)
    assert(def.young_per_egg,"animals.register_egg: could not get egg_time for "
           ..name)

    def.egg_medium = def.egg_medium or "air" -- what egg needs to be in to hatch
    def.egg_replace = def.egg_replace or "air"
    -- what to replace old node with upon egg hatch

    -- egg functions
    def.on_construct = def.on_construct or function(pos, data)
        data = data or minimal.get_nodedef(pos)
        local egg_time = data and data.egg_time
        assert(egg_time,"animal egg couldn't get egg_time: "..(data and data.name
                                                               or "unknown egg"))
        minetest.get_node_timer(pos):start(math.random(egg_time,egg_time*2))
    end

    def.on_timer = def.on_timer or function(pos, elapsed, data)
        data = data or minimal.get_nodedef(pos)
        assert(data,"animal egg couldn't get data of self at "..
               minetest.pos_to_string(pos))
        local egg_time = data.egg_time
        assert(egg_time,"animal egg couldn't get egg_time: "..(data.name))
        -- if custom egg_conditions_correct function then prioritize that
        --  otherwise hatch is true, new_time is nil
        local hatch,new_time = (data.egg_conditions_correct
                                and data.egg_conditions_correct(pos, data))
            or true,nil
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
            return animals.hatch_egg(pos, data)
        elseif type(hatch) == "number" and hatch > 0 then
            -- random chance
            if random() <= hatch then
                return animals.hatch_egg(pos, data)
            end
        end
        -- continue to try to hatch, at another time
        new_time = data.egg_time or 100
        minetest.get_node_timer(pos):start(random(new_time,new_time*2))
        return false
    end

    -- egg_conditions_correct(pos, data)
    -- create a custom function that checks whether or not an egg should hatch
    -- should be provided with a table of some data to be used, but
    -- do not depend on it, run minimal.get_nodedef(pos) if nil

    -- should return true for if it can hatch (return true)
    -- return decimal for percentage chance (return 0-1)
    -- return false if it cannot hatch and provide a new time to use
    --  or it'll default (return false,num)
    -- "new time" parameter can be made boolean true to prevent egg
    --  from hatching permanently (return false,true)
    -- end

    -- register egg
    def.name = name
    minetest.register_node(name,def)
    if animal then
        animal.egg = def.name
    end
end

animals.registered_animals = {}



-- animals.register_animal register_animal
-- register an animal with setup values for ease of programming
-- will be set with the following boolean values: animal (can be false/true, defaults true), mob (will always be true)
function animals.register_animal(name,def)
    assert(type(name) == "string",
        "animals.register_animal: given name is not a string, got type '"..
        tostring(name).."'")
    assert(type(def) == "table",
        "animals.register_animal: provided definition is not a table, got type '"..
        tostring(def).."'")
    assert(type(def.logic) == "function",
        "animals.register_animal: no 'logic' function provided for definition, got type '"..
        tostring(def.logic).."'")

    -- fix name properly
    -- colon at first part of string, indicative of no modname
    -- no colon, no mod name or colon associated, add one
    name = name:sub(1,1) == ":" and minetest.get_current_modname()..name or
        not name:match(":") and minetest.get_current_modname()..":"..name or name
    def.name = name

    -- basic mob booleans for identification
    def.mob = true
    def.animal = type(def.animal) ~= "boolean" and true or def.animal

    -- initial properties
    local init_prop = def.initial_properties or {}
    init_prop.max_hp = init_prop.max_hp or 1
    init_prop.physical = true
    init_prop.collide_with_objects = true
    init_prop.collision_box = init_prop.collision_box
        or {-0.1,-0.1,-0.1,0.1,0.1,0.1}
    init_prop.visual_size = init_prop.visual_size
        or {x = 1, y = 1}
    init_prop.makes_footstep_sound =
        type(init_prop.makes_footstep_sound) ~= "boolean" and true
        or init_prop.makes_footstep_sound
    init_prop.timeout = 0
    def.initial_properties = init_prop

    -- animal stats
    -- base_vals used for ease of calculation later
    local base_vals = {
        energy_egg = 20, -- energy dedicated to the egg
        lifespan = 500, -- seconds your animal will survive in total
        oxygen_min = def.lung_capacity,
        -- custom, minimum amount of oxygen maintained until it tries to resurface
        mature_age = "nil",
        -- custom, seconds until your animal is mature enough to have babies
    }
    -- energy
    def.energy_max = def.energy_max or 100
    -- total units your animal can survive without food
    def.energy_loss = def.energy_loss or 0.25
    -- how much energy your animal loses per second

    -- lifespan and eggs
    -- def.lifespan: see base_vals
    -- def.mature_age: see base_vals
    def.egg_time = def.egg_time or 60*5
    -- seconds until your animal's egg hatches (default 5 minutes)
    def.young_per_egg = def.young_per_egg or 1
    -- how many young will hatch from the egg

    -- (energy_egg will be divided up to how many offspring spawn)
    -- so 4 offspring will have energy_egg be split into 4 (or 20/4 = 5 units)
    --  for each of the young)
    -- can be a table, such as {1,3} to spawn a chance of 1 to 3 per egg hatch
    -- emergency_egg_chance = 0.5: should be handled in on_death

    -- temp (minimum and maximum comfortable temperatures)
    def.min_temp = def.min_temp or -10
    def.max_temp = def.max_temp or 10
    -- breathing
    def.lung_capacity = def.lung_capacity or 5
    -- def.oxygen_min: see base_vals
    -- def.breathing_rate: how much oxygen is recovered per second when in
    -- an ideal environment

    -- is it land-borne (1), sea-borne (2), or amphibious (3)
    -- default land-borne
    def.class = def.class or 1

    -- movement
    def.springiness = def.springiness or 0
    def.buoyancy = def.buoyancy or 1.01
    def.max_speed = def.max_speed or 1 -- m/s
    def.jump_height = def.jump_height or 1.2 -- nodes/meters
    def.view_range = def.view_range or 3 -- nodes/meters

    -- attack
    def.attack = def.attack or {}
    def.attack.range = def.attack.range or 0.3
    def.attack.damage_groups = def.attack.damage_groups or {fleshy=1}

    -- social interactions
    -- (should be defined prior to registered animal code for get_interactors() )
    def.predators = def.predators or animals.get_interactors(name,"predators")
    def.prey = def.prey or animals.get_interactors(name,"prey")
    def.rivals = def.rivals or animals.get_interactors(name,"rivals")
    def.friends = def.friends or animals.get_interactors(name,"friends")
    -- other forms of interactions (should be defined in animal registration)
    --predator_interactions = {
    --default = 0.05 -- fight chance (95% flee chance)
    -- can specify specific predators such as "animals:darkasthaan = 0.5"
    --}
    --capture_interactions = {
    -- capture chance
    -- uses item group to determine capture possibility
    -- hand = 0.75, -- interactions with empty hand
    --club = { -- tool with club group
    -- allow for specification of a table for higher capture groups
    --  (if greater than the highest, will use highest)
    --[1] = 0.1,
    --[2] = 0.25,
    --[3] = 0.4,
    --},
    --}

    -- mobkit dependency
    def.on_step = def.on_step or mobkit.stepfunc
    def.on_activate = def.on_activate or mobkit.actfunc
    def.get_staticdata = def.get_staticdata or mobkit.statfunc

    -- animations
    def.animation = def.animation or {
        -- create animations for your animal
                                     }

    -- sounds
    -- create sounds for your animal
    -- use animals.make_sound(self,name) to play them
    -- animals.make_sound can have a list of "alternatives" to play
    local sounds = def.sounds or {}
    sounds.punch = sounds.punch or { -- plays when animal is punched
        name = "animals_punch",
        gain={0.5, 1.2},
        fade={0.5, 1.5},
        pitch={0.5, 1.5},
    }
    -- opt out of punch_death by setting to false
    sounds.punch_death = sounds.punch_death or sounds.punch_death ~= false and {
        -- plays if animal is punched while dead
        name = "animals_punch_death",
        gain = {1,1.5},
        fade = {0.5,1.5},
        pitch = {0.5,0.8},
     } or nil

    -- drops = {} -- add drops for your animal upon death
    -- set up drops if provided (clear if not a string or table)
    def.drops = type(def.drops) == "string" and {{name=def.drops}} or type(def.drops) == "table" and def.drops or {}
    if def.drops then
        for i,drop in ipairs(def.drops) do
            -- clear if not a table, convert to adequate table if string
            drop = type(drop) == "string" and {name=drop} or type(drop) == "table" and drop or nil
            if drop and drop.name then
                -- set chance, min, and max
                drop.chance = drop.chance or 1
                drop.min = drop.min or 1
                drop.max = drop.max or drop.min
            else -- remove if no name
                drop = nil
            end
            -- update
            def.drops[i] = drop
        end
    end

    -- functions
    def.on_punch = def.on_punch or function(self, puncher, time_from_last_punch,
                                            tool_capabilities, dir, fleshdmg)
        -- optional "fleshdmg" argument
        animals.on_punch(self, puncher, time_from_last_punch,
                         tool_capabilities, dir, fleshdmg)
    end
    -- on_rightclick = function(self, clicker, time_from_last_click,
    --                          tool_capabilities)
    -- _on_death = function(self, pos)
    -- create custom action to occur upon death

    -- used by below for loop
    -- calculates command-based values noted in base_vals
    local function calculate_val(val)
        local data = {
            modifier = val:find("*") or val:find("+") or val:find("/")
                or val:find("-") or val:find("^")
        }
        if data.modifier then
            data.to_index = val:sub(0,data.modifier-1)
            data.number = tonumber(val:sub(data.modifier+1,string.len(val)))
            data.modifier = val:sub(data.modifier,data.modifier)
        else
            return false,
                "animals.register_animal: could not get 'modifier' for '@defname' "..
                "calculation for '@name'."
        end
        -- now if we have a number
        if data.number then
            local use_val = def[data.to_index]
            use_val = type(use_val) == "number" and use_val
                or type(use_val) == "string" and calculate_val(data.to_index)
                or nil
            if type(use_val) == "number" then
                val = (data.modifier == "*" and use_val * data.number
                       or data.modifier == "+" and use_val + data.number
                       or data.modifier == "/" and use_val / data.number
                       or data.modifier == "-" and use_val - data.number or
                       data.modifier == "^" and use_val ^ data.number)
                return val
            else
                return false,"animals.register() could not get '"..data.to_index..
                    "' as number for modification for '@defname' for animal "..
                    "'@name'. Using default."
            end
        else
            return false,
                "animals.register_animal: could not parse '@defname' as "..
                "number for '@name'. Using default."
        end
    end
    -- iterate over and adjust some values (if applicable)
    -- iterate over base_vals (intended to be dependent)
    for defname,basevalue in pairs(base_vals) do
        -- meant to be numbers, but are strings for calculation
        -- allow for custom usage of adding, multiplying, dividing,
        --  or subtracting from a value via string
        local defvalue = def[defname]
        -- grab value from def, if string then proceed with calculations
        if type(defvalue) == "string" then
            defvalue = defvalue:gsub(" ","") -- erase all spaces
            -- convert to table for a command system
            -- should be defined as so: "energy_max*5"
            -- reference a number and use proper index (will be CASE SENSITIVE)
            -- will NOT work with MULTIPLE arguments
            local val, errmsg = calculate_val(defvalue)
            if val ~= false then
                def[defname] = val
                -- got an error, not the end of the world
            else
                val = basevalue ~= "nil" and basevalue or nil
                errmsg:gsub("@defname",defname)
                errmsg:gsub("@name",name)
                minetest.log("error", errmsg)
            end
        end
    end

    def.egg = (def.egg and animals.register_egg(def.egg, def)) or nil

    -- spawnegg
    local spawnegg = def.spawnegg or {}
    -- error would only happen if you have spawnegg set,
    --  but not as a table - nil is fine as basedef will fill in
    assert(type(spawnegg) ==
           "table","animals.register_animal: defined 'spawnegg' is not a "..
           "table for itemdef, got "..type(spawnegg))
    def.spawnegg = animals.register_spawnegg(name, spawnegg, def)

    -- fix or issue errors about improperly set capture_interactions
    if def.capture_interactions then
        -- must be specified as a table if not nil
        if type(def.capture_interactions) ~= "table" then
            error("animals.register_animal: defined 'capture_interactions' "..
                  "is not a table, got '"..type(def.capture_interactions.."'"))
        end
        -- let's fix anything wrong
        for capname, capvalue in pairs(def.capture_interactions) do
            -- overall group effectiveness
            if type(capvalue) == "number" then
                def.capture_interactions[capname] = {capvalue}
                -- group value variations
            elseif type(capvalue) == "table" then
                for gn,strength in pairs(capvalue) do
                    if type(gn) == "number" then
                        -- convert to number or nil (get rid of index)
                        strength = type(strength) == "number" and strength
                            or tonumber(strength)
                        capvalue[gn] = strength
                        -- remove this index if not a proper number index
                    else
                        capvalue[gn] = nil
                    end
                end
                capvalue = def.capture_interactions[capname]
                -- update for calculation

                -- remove empty tables
                if #capvalue == 0 then
                    def.capture_interactions[capname] = nil
                end
                -- error, did not get table or number
            else
                minetest.log("error",
                             "animals.register_animal: capture_interactions: "..
                             "animal capture group index '"..
                             tostring(capname)..
                             "' got invalid value for capture percentage, got '"
                             ..type(capvalue).."'. Clearing.")
                def.capture_interactions[capname] = nil
            end
        end
    end
    -- fix up a default for predator_interactions if provided
    if type(def.predator_interactions) == "number" then
        def.predator_interactions = {default = def.predator_interactions}
    elseif (type(def.predator_interactions) == "table"
            and type(def.predator_interactions[1]) == "number"
            and type(def.predator_interactions.default) ~= "number") then
        def.predator_interactions.default = def.predator_interactions[1]
    end
    -- set values for excessively harmful temps
    def.killer_min_temp = (type(def.killer_min_temp) == "number"
                           and def.killer_min_temp
                           or def.min_temp - 7)
    def.killer_max_temp = (type(def.killer_max_temp) == "number"
                           and def.killer_max_temp
                           or def.max_temp + 25)
    def.burn_max_temp = (type(def.burn_max_temp) == "number"
                         and def.burn_max_temp
                         or def.max_temp + 55)
    def.absolute_death_temp = (type(def.absolute_death_temp) == "number"
                               and def.absolute_death_temp
                               or def.burn_max_temp + 300)
    -- set values for aggression and warn distances
    -- warn is for when it begins warning the rival/predator
    -- aggression is for when it goes on the attack
    def.warn_distance
        = type(def.warn_distance) == "number" and def.warn_distance
        or math.ceil(def.view_range*0.8)
    def.aggression_distance =
        type(def.aggression_distance) == "number" and def.aggression_distance
        or def.warn_distance/2
    -- add reference points to initial_properties inside of the entity
    def.max_hp = def.initial_properties.max_hp
    def.visual_size = def.initial_properties.visual_size
    def.collisionbox = def.initial_properties.collisionbox
    -- stepheight
    def.stepheight = def.stepheight
        or def.class ~= 2 and 1.05
        or nil
    -- modify functions for event changes or necessary actions
    local on_punch = def.on_punch
    def.on_punch = function(self, puncher, time_from_last_punch,
                            tool_capabilities, dir)
        local multiplier = tool_capabilities.full_punch_interval or 0.1
        multiplier = math_clamp(time_from_last_punch / multiplier, 0, 1)
        local fleshdmg = tool_capabilities.damage_groups.fleshy or 0
        -- allow players in creative to infinitely hit
        if not minimal.player_in_creative(puncher) then
            fleshdmg = math.floor(fleshdmg * multiplier)
            -- capture override for sea creatures
            if def.class == 2 and minetest.is_player(puncher)
                and node_drawtype(puncher:get_pos()) == "liquid" then

                local w_itemdef = puncher:get_wielded_item():get_definition()
                tool_capabilities = w_itemdef.tool_capabilities
                    or tool_capabilities
                -- player punching does not give custom tool_capabilities
                if type(def.on_rightclick) == "function" and
                    not tool_capabilities.harm_fish then

                    tool_capabilities.is_hand = true
                    return def.on_rightclick(self, puncher, time_from_last_punch,
                                             tool_capabilities)
                end
            end
        end
        if fleshdmg <= 0 then
            return
        end
        self.last_punched = get_time()
        if type(on_punch) == "function" then
            return on_punch(self, puncher, time_from_last_punch,
                            tool_capabilities, dir, fleshdmg)
        end
    end
    if type(def.on_rightclick) == "function" then
        local on_rightclick = def.on_rightclick
        def.on_rightclick = function(self, clicker, time_from_last_click,
                                     tool_capabilities)
            -- create artificial on_punch functionality for rightclick
            local tool = clicker:get_wielded_item()
            local tooldef = tool:get_definition()
            tool_capabilities = tool_capabilities or tooldef.tool_capabilities
            time_from_last_click = time_from_last_click
                or get_time(animals.rclick_times[clicker])
            animals.rclick_times[clicker] = get_time()
            if type(on_rightclick) == "function" then
                return on_rightclick(self, clicker, time_from_last_click,
                                     tool_capabilities)
            end
        end
    end
    -- entity functions
    -- set and modify
    function def.set(self,vname,value,memorize)
        if type(self) ~= "table" and type(self) ~= "userdata" then
            return value
        end
        -- set a value
        self[vname] = value
        if memorize then
            mobkit.remember(self,vname,value)
        end
        return value
    end
    function def.modify(self,vname,value,memorize)
        -- modify a value
        if type(vname) ~= "string" or type(value) ~= "number"
            or (type(self) ~= "table" and type(self) ~= "userdata")
            or type(self[vname]) ~= "number" then

            return value
        end
        value = self:set(vname, self[vname] + value, memorize)
        return value
    end
    -- age mechanics (opt out with false)
    def.age_mechanics = type(def.age_mechanics) == "function" and def.age_mechanics or
        def.age_mechanics ~= false and animals.age_mechanics or nil

    -- creature
    minetest.register_entity(name,def)
    -- add to registered animals table
    animals.registered_animals[name] = minetest.registered_entities[name]
    return minetest.registered_entities[name]
end
