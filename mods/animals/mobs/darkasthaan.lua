----------------------------------------------------------------------
-- Darkasthaan

--[[
    a big spider for deep caves
    much same as kubwakubwa, but more dangerous
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
        if prty < 50 then


            --Threats
            local plyr = animals.get_nearby_player(self)
            if plyr then
                prty = 55
                animals.fight_or_flight(self, plyr, prty, 0.75)
                self.conserve = false -- not hibernating anymore
            end

            --currently has none
            --animals.predator_avoid(self, 55, 0.75)
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
            --when in prime condition
            if random() < 0.1
                and not rival
                and self.hp >= self.max_hp
                and self.energy >= self.energy_egg*2
                and age >= self.mature_age then
                animals.place_egg(self, pos)
            end
        elseif self.conserve == true then
            -- found food, get outta hibernation
            self.conserve = not animals.prey_hunt(self, 40)
        end

        -------------------
        --generic behaviour
        if mobkit.is_queue_empty_high(self) and self.conserve ~= true then
            mobkit.animate(self,'walk')
            animals.hq_roam_dark(self,10,1)
        end
    end
end






---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF DARKASTHAAN INTERACTOR SETTINGS
animals.add_interactors(
    "animals:darkasthaan","prey", 
    "animals:kubwakubwa",
    "animals:pegasun", "animals:pegasun_male",
    "animals:chichasa", "animals:chichasa_male",
    "animals:sneachan", "animals:impethu", 
    "animals:gundu", "animals:sarkamos")
animals.add_interactors("animals:darkasthaan","rivals", "self")

----------------------------------------------
-- Animal Data
local self_data = {
    name = "animals:darkasthaan",
    --core
    initial_properties = {
        max_hp = 200,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.3, -0.3, -0.3, 0.3, 0, 0.3},
        visual = "mesh",
        mesh = "animals_darkasthaan.b3d",
        textures = {"animals_darkasthaan.png"},
        visual_size = {x = 0.6, y = 0.6},
        makes_footstep_sound = true,
        _VH1_barheight = -20, -- lowers VH1 hp bar by 1 node
    },
    _desc = S("Darkasthaan"),
    timeout = 0,

    -- animal stats
    max_hp = 200,
    lung_capacity = 40,
    breathing_rate = 8,
    -- comfort temps
    min_temp = 14,
    max_temp = 70,
    -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
    class = 1,
    -- animal stats
    lung_capacity = 40,
    breathing_rate = 8,
    -- comfort temps
    min_temp = 14,
    max_temp = 80,
    -- is it land-borne (1), sea-borne (2), or amphibious (3)?
    class = 1,
    -- energy
    energy_max = 12000,--secs it can survive without food
    egg_time = 60*30,
    young_per_egg = {1,3}, --will get this/energy_egg starting energy
    -- cannot define conservation minimum + energy_egg
    -- (energy_egg being necessary for cn_min) in API
    --  due to multiple values needed
    -- lifespan
    lifespan = "energy_max*12",
    mature_age = "energy_max*0.1",
    -- interactions
    -- prey + rivals automatically defined in registration
    capture_interactions = {
        club = 0.04,
    },
    player_interaction = 0.99,
    -- logic for mobkit
    logic = brain,
    --movement
    springiness=0,
    buoyancy = 1.01,
    max_speed = 1,                                       -- m/s
    jump_height = 2,                             -- nodes/meters
    view_range = 10,                                     -- nodes/meters
    --attack
    attack={range=0.8, damage_groups={fleshy=12}},
    armor_groups = {fleshy=100},
    -- animations + sounds
    animation = {
        walk={range={x=1,y=21},speed=15,loop=true},
        fast={range={x=1,y=21},speed=35,loop=true},
        stand={range={x=25,y=45},speed=5,loop=true},
        dead = {range ={x=0, y=0},speed = 0,loop=false},
    },
    sounds = {
        warn = {
            name = "animals_darkasthaan_warn",
            gain={0.3, 0.7},
            fade={0.5, 1.5},
            pitch={0.4, 1.4},
        },
    },
    --on actions
    drops = {
        {name = "animals:carcass_invert_large", chance = 1, min = 1, max = 1,},
    },
    on_rightclick = function(self, clicker, time_from_last_click,
                             tool_capabilities)
        if animals.stun_catch_mob(self, clicker, time_from_last_click,
                                  tool_capabilities) then -- attack kidnapper
            animals.fight_or_flight(self, clicker, nil, 1)
        end
    end,
    -- eggs
    egg = {
        tiles = {"animals_darkasthaan_eggs.png"},
        node_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125,  0.125, -0.375, 0.125},
        },
    },
    -- spawnegg or live animal
    spawnegg = {
        desc = S("Live Darkasthaan")
    },
}
self_data.energy_egg = self_data.energy_max/3  --energy that goes to egg
self_data.cn_min = (self_data.energy_egg / self_data.young_per_egg[2]) * 0.7
-- conserve min (minimum point at when to conserve energy)
animals.register_animal("animals:darkasthaan",self_data)
