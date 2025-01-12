----------------------------------------------------------------------
-- Sneachan
--small insect.
--[[
    Land living
    Dislikes bright light, eats sediment, plants,
]]
---------------------------------------------------------------------
animals = animals
mobkit = mobkit

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor



-----------------------------------
local function brain(self)
    -- calculate instantanious effects
    animals.core_hp(self)

    if mobkit.timer(self,1) then

        local pos = mobkit.get_stand_pos(self)

        --die from exhaustion or age
        if not animals.core_life(self, pos) then
            return
        end
        local age = self.age

        ------------------
        --Emergency actions


        local prty = mobkit.get_queue_priority(self)
        -------------------
        --High priority actions
        local pred

        if prty < 50 then


            --Threats
            local plyr = animals.get_nearby_player(self)
            if plyr then
                animals.fight_or_flight(self, plyr)
            end

            pred = animals.predator_avoid(self)

        end


        ----------------------
        --Low priority actions

        if prty < 20 then

            --territorial behaviour
            local rival = animals.territorial(self, true)


            --feeding
            local light = (minetest.get_node_light(pos) or 0)
            local badlight = light <= 12

            --hungry, go eat stuff
            if self.energy < self.energy_max then
                local foodfuncs -- declare for self indexing
                -- less effective eating in day
                foodfuncs = {
                    -- eat flora
                    flora_suc = function(self, lprty)
                        self:modify('energy',(badlight and 10 or 4))
                        if random() < (badlight and 0.005 or 0.001) then
                            animals.eat_flora(pos, 1)
                        end
                    end,
                    flora_fail = function(self, lprty)
                        animals.hq_roam_walkable_group(self, lprty, 'spreading', nil,
                          foodfuncs.spreading_suc, foodfuncs.spreading_fail)
                    end,
                    spreading_suc = function(self, lprty)
                        self:modify('energy', (badlight and 5 or 1))
                        if random() < (badlight and 0.008 or 0.001) then
                            animals.eat_grassy_sediment_under(pos, 1)
                        end
                    end,
                    spreading_fail = function(self, lprty)
                        --wander for food
                        -- 10% if too bright
                        if light <= 12 or random() < 0.1 then
                            animals.animate(self,'walk')
                            animals.hq_roam_walkable_group(self, lprty, {'spreading', 'flora'}, 'cane_plant',
                              -- 90% chance to just randomly roam or 30% if day
                              nil, (random() < (badlight and 0.3 or 0.9) and mobkit.hq_roam or animals.hq_roam_dark))
                        --wander random
                        else
                            animals.animate(self,'walk')
                            mobkit.hq_roam(self, 9)
                        end
                    end
                }
                -- if it's day, then we have a chance of just... not wanting to eat today
                if badlight or random() < 0.5 then
                    animals.hq_roam_walkable_group(self, 14, 'flora', 'cane_plant',
                      foodfuncs.flora_suc, foodfuncs.flora_fail)
                -- clear queue in favour of darkness seeking
                elseif random() < 0.5 then
                    mobkit.clear_queue_high(self)
                -- wander random
                elseif random() < 0.05 then
                    animals.animate(self,'walk')
                    mobkit.hq_roam(self, 8)
                end
            end

            --reproduction
            --asexual parthogenesis, eggs
            -- full health, no rival or pred
            if self.hp >= self.max_hp and not (rival or pred) then
                -- energy over 140% of energy_max and on 0.8% chance
                if self.energy >= self.energy_egg * 1.4 and random() < 0.008 then
                    animals.place_egg(self, pos)
                -- higher chance of laying eggs near death
                elseif self.energy > self.energy_egg * 1.05 and self.age >= self.lifespan * 0.8 and
                    random() < 0.05 then
                    animals.place_egg(self, pos)
                -- don't even depend on checking own energy
                elseif self.energy > 25 and self.age >= self.lifespan * 0.935 then
                  -- 15% for over 93.5% lifespan, 35% for over 96% lifespan,
                  -- 80% for over 98% lifespan
                  local lay_chance = self.age > self.lifespan * 0.98 and 0.8
                      or self.age > self.lifespan * 0.96 and 0.35 or 0.15
                      animals.emergency_egg(self, pos, nil, lay_chance)
                end
            end

        end

        -------------------
        --generic behaviour
        if mobkit.is_queue_empty_high(self) then
            animals.animate(self,'walk')
            animals.hq_roam_dark(self,10,1)
        end
    end
end






---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF SNEACHAN INTERACTOR SETTINGS
animals.add_interactors("animals:sneachan","predators",
                        "animals:pegasun", "animals:pegasun_male",
                        "animals:chichasa", "animals:chichasa_male",
                        "animals:kubwakubwa", "animals:darkasthaan")
-- don't need to tell impethu we're a rival of them
animals.add_interactors("animals:sneachan","rivals", "self", "animals:impethu", false)

-- Animal Data
local self_data -- define earlier for utilization in functions
self_data = {
    initial_properties = {
        max_hp = 3,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.1, -0.01, -0.1, 0.1, 0.15, 0.1},
        visual = "mesh",
        mesh = "animals_sneachan.b3d",
        textures = {"animals_sneachan.png"},
        visual_size = {x = 1, y = 1},
        makes_footstep_sound = true,
    },
    _desc = S("Sneachan"),
    timeout = 0,

    -- animal stats
    lung_capacity = 10,
    -- comfort temps
    min_temp = 1,
    max_temp = 50,
    -- is it land-borne (1), sea-borne (2), or amphibious (3)?
    class = 1,
    -- energy
    energy_max = 5000,--secs it can survive without food
    energy_egg = "energy_max*0.5",--(self_data.energy_max*0.5)
    --energy that goes to egg
    egg_time = 60*10,
    young_per_egg = {3,7}, --will get this/energy_egg starting energy
    emergency_egg_chance = 0.9,
    -- lifespan
    lifespan = "energy_max*2",
    -- interactions
    -- predators + rivals automatically defined in registration
    consume_predators = false,
    player_interaction = 0.01,
    predator_interactions = 0.01, -- fight chance against preds
    capture_interactions = {
        hand = 0.85,
        club = 1,
    },
    -- logic for mobkit
    logic = brain,
    --movement
    springiness=0,
    buoyancy = 1.01,
    max_speed = 1,                                       -- m/s
    --attack
    attack={range=0.3, damage_groups={fleshy=1}},
    armor_groups = {fleshy=100},
    -- settings
    max_pop = 20,
    animation = {
        walk={range={x=0, y=20}, speed=20, loop=true},
        fast={range={x=0, y=20}, speed=40, loop=true},
        stand={range={x=0, y=20}, speed=10, loop=true},
        dead = {range ={x=0, y=0},speed = 0,loop=false},
    },
    sounds = {
        warn = {
            name = "animals_sneachan_warn",
            gain={0.05, 0.2},
            fade={0.5, 1.5},
            pitch={0.6, 1.3},
        },
    },
    --on actions
    drops = "animals:carcass_invert_small",
    on_rightclick = function(self, clicker, time_from_last_click,
                             tool_capabilities)
        animals.stun_catch_mob(self, clicker, time_from_last_click,
                               tool_capabilities)
        animals.fight_or_flight(self, clicker)
    end,
    _on_death = function(self, pos)
        local good_temp,temp_status = animals.temp_comfy(self)
        if good_temp or temp_status ~= "cold" then
            return
        end
        animals.emergency_egg(self, pos)
    end,
    -- eggs
    egg = {
        tiles = {"animals_sneachan_eggs.png"},
        egg_conditions_correct = function(pos,data)
            data = data or minimal.get_nodedef(pos)
            if not data then return false,true end -- break egg
            local egg_time = data.egg_time
            local temp = climate.get_point_temp(pos)
            local light = (minetest.get_node_light(pos) or 0)
            local comflight = light <= 10 -- comfortable light
            -- comfortable temp ("day" more than 18C, more than 9C otherwise)
            local comftemp = comflight and temp > 9 or temp > 18
            -- if temp comfy: hatch chance of 30% if "day" otherwise hatch or seek a new hatching time
            -- double time for hatching again if uncomfortable temp
            return (comftemp and (comflight or 0.3) or false), (not comftemp and random(egg_time*2, egg_time*4) or nil)
        end,
    },
    -- spawnegg (live animal) handled in animal registration
}
animals.register_animal("animals:sneachan",self_data)
