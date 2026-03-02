----------------------------------------------------------------------
-- Impethu
--cave worm.
--[[
    Bottom of shallow cave food chain
]]
---------------------------------------------------------------------

animals = animals
mobkit = mobkit

-- Internationalization
local S = animals.S

local random = math.random


-----------------------------------
local function brain(self)
    -- calculate instantaneous effects
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
                animals.fight_or_flight(self, plyr)
            end

            animals.predator_avoid(self)

        end

        local light = (minetest.get_node_light(pos) or 0)
        if (light > self.max_light) then
            --fatigued by light

            self:modify('energy',-random(2,6))
            if (prty <= 46) then
                --random search for darkness (now better :D)
                prty = 46
                animals.hq_roam_dark(self,46)
            end
        end

        ----------------------
        --Low priority actions

        if prty < 20 then

            --territorial behaviour
            local rival
            if random() < 0.7 then
                rival = animals.territorial(self, false)
            else
                rival = animals.territorial(self, true)
            end


            --feeding
            --eat stuff in the dark
            if light <= self.max_light then
                animals.animate(self,'walk')
                if not rival and self.energy < self.energy_max then
                    -- actively find nodes to eat at
                    if random() <= 0.7  then
                        animals.hq_roam_walkable_group(self, 'stone', nil, 15)
                    else
                        animals.hq_roam_walkable_group(self, 'sediment', nil, 15)
                    end
                    local u_node = minetest.get_node(pos+vector.new(0,-1,0))
                    -- why use several get_item_group calls?
                    u_node = minimal.merge_tables(u_node,
                                                  minetest.registered_nodes[
                                                      u_node.name] or {})
                    if u_node.groups then
                        if u_node.groups.stone
                            or u_node.groups.boulder then
                            -- only eat stuff on natural stone
                            self:modify('energy',1)
                        elseif u_node.groups.sediment
                            and (animals.eat_sediment_under(pos,0.01)) then

                            self:modify('energy',random(3,5))
                        end
                    end
                else
                    mobkit.hq_roam(self,10)
                end
            end


            --reproduction
            --asexual parthogenesis, eggs
            if random() < 0.008 then
                if not rival
                    and self.energy >= (self.energy_max * 0.95) then
                    animals.place_egg(self, pos)
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

-- SETTING OF IMPETHU INTERACTOR SETTINGS
animals.add_interactors("animals:impethu","predators",
                        "animals:pegasun", "animals:pegasun_male",
                        "animals:chichasa", "animals:chichasa_male",
                        "animals:kubwakubwa",
                        "animals:darkasthaan")
-- don't need to tell sneachan we're a rival of them
animals.add_interactors("animals:impethu","rivals", "animals:sneachan", "self", false)

----------------------------------------------
-- The Animal
local self_data -- define earlier for utilization in functions
self_data = {
    initial_properties = {
        max_hp = 3,

        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.09, -0.25, -0.09, 0.09, -0.1, 0.09},
        visual = "mesh",
        mesh = "animals_impethu.b3d",
        textures = {"animals_impethu.png"},
        visual_size = {x = 5, y = 5},
        makes_footstep_sound = false,
        timeout = 0,
    },
    _desc = S("Impethu"),
    _VH1_barheight = 1,

    -- animal stats
    max_hp = 3,
    lung_capacity = 10,
    breathing_rate = 4,
    -- comfort temps
    min_temp = 5,
    max_temp = 70,
    -- comfort light
    max_light = 6,
    -- is it land-borne (1), sea-borne (2), or amphibious (3)?
    class = 1,
    -- settings
    max_pop = 10,
    -- energy and eggs
    energy_max = 6000,   --secs it can survive without food
    energy_egg = "energy_max*0.7",  --energy that goes to egg
    egg_time = 60*10,
    young_per_egg = {2,4}, --will get this/energy_egg starting energy
    emergency_egg_chance = 0.95,
    -- lifespan
    lifespan = "energy_max*4",
    -- interactions
    -- predators + rivals automatically defined in registration
    consume_predators = false,
    player_interaction = 0.02,
    predator_interactions = 0.02,
    capture_interactions = {
        hand = 0.7,
        club = 1,
    },
    -- logic for mobkit
    logic = brain,
    --movement
    springiness=0,
    buoyancy = 1.01,
    max_speed = 0.5,                                     -- m/s
    -- animation
    animation = {
        walk={range={x=0, y=12}, speed=10, loop=true},
        fast={range={x=0, y=12}, speed=10, loop=true},
        stand={
            {range={x=12, y=24}, speed=5, loop=true},
            {range={x=24, y=31}, speed=5, loop=true},
        },
        dead = {range ={x=0, y=0},speed = 0,loop=false},
    },
    sounds = {
        warn = {
            name = "animals_impethu_warn",
            gain={0.1, 0.4},
            fade={0.5, 1.5},
            pitch={0.5, 1.5},
        },
    },
    -- attack
    attack={range=0.3, damage_groups={fleshy=1}},
    armor_groups = {fleshy=100},
    --on actions
    drops = "animals:carcass_invert_small",
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
        tiles = {"animals_sneachan_eggs.png^[multiply:#c49a82"},
        egg_conditions_correct = function(pos,data)
            data = data or minimal.get_nodedef(pos)
            if not data then return false,true end -- break egg
            local egg_time = data.egg_time
            local temp = climate.get_point_temp(pos)
            -- light equal to or less than tolerable light
            local comflight = (minetest.get_node_light(pos) or 0) <= self_data.max_light
            -- darkness must have a warm temp of 14, otherwise a day temp can be 8
            local comftemp = comflight and temp > 14 or temp > 8
            -- 5% chance to hatch in bad light - if hatch fails, then increase egg_time length on random
            return (comftemp and (comflight or 0.05) or false), random(egg_time, egg_time*6)
        end,

    },
    -- spawnegg (live animal) handled in animal registration
}
animals.register_animal("animals:impethu", self_data)
