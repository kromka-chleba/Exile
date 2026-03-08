----------------------------------------------------------------------
-- Kubwakubwa
--a spider
--[[
    Predator in shallow caves
]]

---------------------------------------------------------------------

animals = animals
mobkit = mobkit

-- Internationalization
local S = animals.S

local random = math.random


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

        ------------------
        --Emergency actions

        local prty = mobkit.get_queue_priority(self)
        -------------------
        --High priority actions
        if prty < 50 then

            --Threats
            local plyr = animals.get_nearby_player(self)
            if plyr then
                prty = 55
                animals.fight_or_flight(self, plyr, prty, 0.15)
            end

            if (animals.predator_avoid(self) or plyr) then
                prty = 55
                self.conserve = false -- on the move, no more conserving
            end

        end

        if self.isinliquid then
          self.isonground = true
        end

        ----------------------
        --Low priority actions

        if prty < 20 and self.conserve ~= true then

            --territorial behaviour
            local rival = animals.territorial(self, true)


            --feeding
            --hunt prey
            if self.energy < self.energy_max then
                if not animals.prey_hunt(self, 25) then
                    --random search for darkness
                    animals.hq_roam_dark(self,15)

                    if (self.energy <= self.cn_min) then
                        -- stop all activity, we're conserving our energy!
                        mobkit.clear_queue_low(self)
                        mobkit.clear_queue_high(self)
                        self.conserve = true
                    end
                end
            end

            --reproduction
            --asexual parthogenesis, eggs
            --health is fine, of age, and no rival
            if self.hp >= self.max_hp and self.age > self.mature_age and not rival then
                --when in prime condition
                if self.energy >= self.energy_egg + 100 and random() < 0.05 then
                    animals.place_egg(self, pos)
                -- if very old and on 80% chance, lay egg and die, we were gon die soon anyways
                elseif self.age >= (self.lifespan * 0.9) and random() < 0.8
                    and self.energy >= 25 then

                    animals.emergency_egg(self, pos, nil, 0.8)
                    return
                end
            end
        elseif self.conserve == true then
            -- found prey, get out of hibernation
            self.conserve = not animals.prey_hunt(self, 40)
        end

        prty = mobkit.get_queue_priority(self)
        -- why am I just idling in water? let's get outta here lol
        if prty < 15 and self.isinliquid then
            -- why am I just idling in water? let's get outta here lol
            animals.hq_liquid_recovery(self,60)
        end

        -------------------
        --generic behaviour
        if mobkit.is_queue_empty_high(self) and self.conserve ~= true then
            animals.animate(self,'walk')
            animals.hq_roam_dark(self,10,1)
        end
    end
end




---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF KUBWAKUBWA INTERACTOR SETTINGS
animals.add_interactors("animals:kubwakubwa","predators",
                        "animals:darkasthaan", "animals:sarkamos")
-- don't need to tell male pegasuns we're a rival of them
animals.add_interactors("animals:kubwakubwa","rivals", "self",
                        "animals:pegasun_male", false)

----------------------------------------------
-- Animal Data
local self_data = {
    name = "animals:kubwakubwa",
    --core
    initial_properties = {
        max_hp = 20,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.14, -0.01, -0.14, 0.14, 0.27, 0.14},
        visual = "mesh",
        mesh = "animals_kubwakubwa.b3d",
        textures = {"animals_kubwakubwa.png"},
        visual_size = {x = 1, y = 1},
        makes_footstep_sound = true,
    },
    _desc = S("Kubwakubwa"),
    timeout = 0,


    -- animal stats
    max_hp = 20,
    lung_capacity = 36,
    oxygen_min = "lung_capacity*0.4",
    breathing_rate = 6,
    -- comfort temps
    min_temp = 7,
    max_temp = 60,
    -- is it land-borne (1), sea-borne (2), or amphibious (3)?
    class = 1,
    -- energy
    energy_max = 8000,--secs it can survive without food
    egg_time = 60*20,
    young_per_egg = {3,4}, --will get this/energy_egg starting energy
    emergency_egg_chance = 0.75,
    -- cannot define conservation minimum + energy_egg
    -- (energy_egg being necessary for cn_min) in API
    --  due to multiple values needed
    -- lifespan
    lifespan = "energy_max*5",
    mature_age = "energy_max*0.5",
    -- settings
    max_pop = 23,
    -- interactions
    -- predators + prey + rivals automatically defined in registration
    predator_interactions = 0.15,
    capture_interactions = {
        club = 0.5,
    },
    -- logic for mobkit
    logic = brain,
    --movement
    springiness=0,
    buoyancy = 1.01,
    max_speed = 0.75,                                    -- m/s
    jump_range=5.4,                                      -- nodes/meters
    view_range = 10,                                     -- nodes/meters
    -- attack, used as argument `tool_capabilities`
    attack={range=0.2, damage_groups={fleshy=4}},
    -- position of jaws, will be scaled with visual_size
    attack_orig={x=0.25,y=0.2},
    -- allow attacking players and rivals with 2 hits within 2x4 secs
    attack_interval=4,
    attack_max_hits=2,
    armor_groups = {fleshy=100},
    hunting_depth = 4,
    -- animation + sounds
    animation = {
        walk={range={x=0,y=20},speed=20,loop=true},
        fast={range={x=0,y=20},speed=50,loop=true},
        stand={range={x=20,y=40},speed=10,loop=true},
        dead = {range ={x=0, y=0},speed = 0,loop=false},
    },
    sounds = {
        warn = {
            name = "animals_kubwakubwa_warn",
            gain={0.4, 0.8},
            fade={0.5, 1.5},
            pitch={0.9, 1.1},
        },
    },
    -- on actions
    drops = "animals:carcass_invert_large",
    on_rightclick = function(self, clicker)
        -- show some reaction
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
        tiles = {"animals_kubwakubwa_eggs.png"},
        node_box = {
            type = "fixed",
            fixed = {-0.0625, -0.5, -0.0625,  0.0625, -0.375, 0.0625},
        },
        egg_conditions_correct = function(pos,data)
            data = data or minimal.get_nodedef(pos)
            if not data then return false,true end -- break egg
            local egg_time = data.egg_time
            local temp = climate.get_point_temp(pos)
            if temp < 16 then
                -- too cold to hatch, wait again (with increased time)
                return false,math.random(egg_time,egg_time*3)
            end
            return true
        end,
    },
    -- spawnegg (live animal) handled in animal registration
}
self_data.energy_egg = self_data.energy_max*0.5 --energy that goes to egg
self_data.cn_min = (self_data.energy_egg / self_data.young_per_egg[2]) * 0.4
-- conserve min (minimum point at when to conserve energy)
animals.register_animal("animals:kubwakubwa",self_data)
