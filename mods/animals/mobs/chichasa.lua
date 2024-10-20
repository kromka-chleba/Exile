----------------------------------------------------------------------
-- Chichasa
--small ground bird
--[[
    males and females, must mate to reproduce.
    lives off flora, spreading surface and insects
    small, harmless, difficult to catch or see.
    The peace loving hippy cousin of the mighty pegasun
    Use much the same values as pegasun, so they can be balanced together.
    Search for "NotPegasun" to find values unique to chichasa
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
                animals.fight_or_flight(self, plyr)
            end

            animals.predator_avoid(self)


        end
        local male = self.sex == "male" and true or false
        self.pregnant = not male and (self.pregnant
                                      or (type(self.pregnant) ~= "boolean"
                                          and mobkit.recall(self,'pregnant')))
            or false

        ----------------------
        --Low priority actions
        if prty < 20 then

            --random choice between
            --feeding, exploring, social
            --chance differs by time
            local ce = male and 0.4 or 0.6 -- chance explore (otherwise social)
            local tod = {animals.timeofday()}
            if tod[1] == "night" then
                --more social at night
                ce = 0.08
            elseif tod[1] == "day" and tod[2] == "mid" then
                --explore during midday
                ce = male and 0.6 or 0.9
            end
            local ceat = self.energy <= self.energy_max
                and (male and self.energy_max*.25
                     or self.energy_max*.5)/self.energy
                or -1
            -- chance eat - creates a percentage by dividing a percentage
            --  of energy_max by the current energy
            -- The lower the energy, the higher the percentage
            -- If energy is equal or less than 25% of energy_max,
            --  it will be 1 or higher
            ce = ce + (ceat*0.5) -- we're hungry, modify our chance to explore!

            -- exploring
            if random() < ce then
                mobkit.animate(self,'walk')
                -- let's prioritize eating more
                if ceat >= 0.3 then
                    ceat = ceat + (ce*(ceat/0.5))
                end

                if random() <= ceat then -- sorry guys I need a snack break
                    if male then
                        if (animals.eat_flora(pos,0.001) == true) then -- mmm plants
                            self:modify('energy',18)
                        elseif not (random() <= 0.25
                                    and animals.prey_hunt(self,30)) then
                            --wander randomly for plants if can't find prey
                            mobkit.animate(self,'walk')
                            animals.hq_roam_walkable_group(self, 'flora',
                                                           "cane_plant", 15)
                            -- go for group, ignore group, priority
                        end
                    else
                        if not (random() <= 0.5 and animals.prey_hunt(self,30)) then
                            if (animals.eat_flora(pos,0.003) == true) then
                                self:modify('energy',18)
                            else
                                -- look for flora that's not a cane_plant
                                animals.hq_roam_walkable_group(self, 'flora',
                                                               "cane_plant", 15)
                                -- self, go for group, ignore group, priority
                            end
                        end
                    end
                    -- walkin' around downtown
                elseif random() < 0.98 then
                    --wander random
                    mobkit.hq_roam(self,10)
                else
                    --wander temp
                    animals.hq_roam_comfort_temp(self,12, 21)
                end
                -- social
            else
                self.sexual = self.age >= self.mature_age
                    and self.hp >= self.max_hp and not self.pregnant
                    and self.energy >= (male and self.energy_max*0.25
                                        or self.energy_egg * 1.22)
                -- territorial
                if random()< (male and 0.7 or 0.01) then
                    animals.territorial(self, false)
                    -- sexual behaviours
                elseif self.sexual and random() < (male and 0.95 or 0.75) then
                    --we are randy
                    mobkit.make_sound(self,'mating')
                    local mate = male and animals.mate_assess(self, 'animals:chichasa')
                        or not male and animals.mate_assess(self,
                                                            'animals:chichasa_male')
                    if mate then
                        if male then -- we're going in brothers
                            -- go get her!
                            self:modify('energy',-1000) -- energy use for mating lol
                            animals.hq_mate(self, 25, mate)
                        else
                            --go get him!
                            animals.hq_mate(self, 25, mate)
                        end
                        --self.sexual = false
                    elseif not animals.flock(self, 35) then -- find a mate
                        mobkit.hq_roam(self,40)
                    end
                    --are we already pregnant?
                elseif random() < 0.08 and self.pregnant then
                    mobkit.lq_idle(self,3)
                    if animals.place_egg(self, pos) then
                        self:set('pregnant',false,true)
                    end
                    -- flocking
                elseif not animals.flock(self, 20, self.aggression_distance) then
                    -- hmm... they're not here...
                    if not animals.flock(self, 25, self.warn_distance) then
                        -- umm...
                        if not animals.flock(self, 35) then
                            -- where is everybody?? getting really worried here...
                            mobkit.hq_roam(self,40)
                        end
                    end
                end
            end
        end

        -------------------
        --generic behaviour
        if mobkit.is_queue_empty_high(self) then
            mobkit.animate(self,'walk')
            mobkit.hq_roam(self,10)
        end
    end
end




---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING INTERACTOR SETTINGS
animals.add_interactors("animals:chichasa","predators", "animals:kubwakubwa",
                        "animals:darkasthaan", "animals:sarkamos")
animals.add_interactors("animals:chichasa","friends", "self",
                        "animals:chichasa_male")
animals.add_interactors("animals:chichasa","rivals", "self")

-- MALE INTERACTORS
animals.add_interactors("animals:chichasa_male","friends", "animals:chichasa")
animals.add_interactors("animals:chichasa_male","rivals", "self",
                        "animals:pegasun", "animals:pegasun_male")

------------------------------------------------------------------------
--FEMALE
local self_data = {
    name = "animals:chichasa",
    --core
    -- _desc = "Female Chichasa",
    initial_properties = {
        max_hp = 40,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.25, 0, -0.25, 0.25, 0.5, 0.25,},
        visual = "mesh",
        mesh = "animals_chichasa.b3d",
        textures = {"animals_chichasa.png"},
        visual_size = {x = 6, y = 6},
        makes_footstep_sound = true,
    },
    _desc = S("Female Chichasa"),
    timeout = 0,

    -- animal stats
    max_hp = 40,
    lung_capacity = 20,
    energy_loss = 1,
    breathing_rate = 5,
    -- comfort temps
    min_temp = -24,
    max_temp = 46,
    -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
    class = 1,
    -- settings
    max_pop = 40,
    -- energy
    energy_max = 8000,   --secs it can survive without food
    energy_egg = "energy_max*0.4",  --energy that goes to egg
    egg_time = 60*22,
    young_per_egg = 1,           --will get this/energy_egg starting energy
    -- lifespan
    lifespan = "energy_max*15",
    mature_age = "energy_max*0.2", -- 20% of energy_max (8000) or 1600 --NotPegasun (lower)
    growth_min_size = 0.4,
    -- interactions
    -- predators + rivals automatically defined in registration
    consume_non_prey = false,
    player_interaction = 0.005,
    predator_interactions = 0.005,
    capture_interactions = {
        club = 0.25, --NotPegasun (harder to catch)
    },
    herding_distance = 5, --NotPegasun (scares easier)
    sex = "female",
    -- logic for mobkit
    logic = brain,
    -- animations + sounds
    animation = {
        walk={range={x=41, y=59}, speed=30, loop=true},
        fast={range={x=91, y=110}, speed=45, loop=true},
        stand={
            {range={x=1, y=39}, speed=20, loop=true},
            {range={x=61, y=89}, speed=45, loop=true},
        },
        dead = { range = {x=91, y=99}, speed = 70, loop=false},
    },
    sounds = {
        warn = {
            name = "animals_chichasa_warn",
            gain={0.2, 0.5},
            fade={0.5, 1.5},
            pitch={0.9, 1.1},
        },
        scared = {
            name = "animals_chichasa_scared",
            gain={0.2, 0.3},
            fade={0.5, 1.5},
            pitch={1.3, 1.4},
        },
        call = {
            name = "animals_chichasa_call",
            gain={0.2, 0.4},
            fade={0.5, 1.5},
            pitch={0.9, 1.1},
        },
        mating = {
            name = "animals_chichasa_mate",
            gain={0.4, 0.7},
            fade={0.5, 1.5},
            pitch={1.2,1.7}--{0.9, 1.4},
        },
        attack = {
            name = "animals_chichasa_attack",
            gain={0.4, 0.7},
            fade={0.5, 1.5},
            pitch={0.9, 1.4},
        },
    },
    --movement
    springiness=0,
    buoyancy = 1.01,
    max_speed = 2.5,       -- m/s --NotPegasun (faster)
    jump_height = 1.2,     -- nodes/meters
    view_range = 26,       -- nodes/meters
    warn_distance = 6,     --NotPegasun (shorter distance)
    aggression_distance = 2, --NotPegasun (shorter distance)
    --attack
    attack={range=0.9, damage_groups={fleshy=1}}, --NotPegasun (weaker)
    armor_groups = {fleshy=100},
    --on actions
    drops = "animals:carcass_bird_small",
    on_rightclick = function(self, clicker, time_from_last_click,
                             tool_capabilities)
        animals.stun_catch_mob(self, clicker, time_from_last_click,
                               tool_capabilities)
        animals.fight_or_flight(self, clicker) -- ewww a human touched me!!!
    end,
    -- egg
    egg = {
        description = S('Chichasa Egg'),
        tiles = {"animals_gundu_eggs.png"},
        stack_max = minimal.stack_max_medium,
        node_box = {
            type = "fixed",
            fixed = {-0.125, -0.5, -0.125,  0.125, -0.25, 0.125}, --NotPegasun (smaller)
        },
        groups = {egg = 2},
        egg_hatching = {"animals:chichasa","animals:chichasa_male"},
    },
    -- spawnegg or live animal
    spawnegg = {
        description = S("Live Female Chichasa")
    }
}
self_data = animals.register_animal("animals:chichasa",self_data)
local self_male = table.copy(self_data)
self_male.name = "animals:chichasa_male"
-- don't register egg again for male
self_male.egg = nil
-- modifications for males
-- initial properties
--self_male.logic = brain_male
self_male.initial_properties.max_hp = 45
self_male.initial_properties.textures = {"animals_chichasa_male.png"}
animals.sizeify(self_male,1.15) -- sexual dimorphism, male bigger then female (15%)
-- physical properties
self_male.max_speed = 3  --NotPegasun (faster)
self_male.jump_height = 1.5
-- male energy, lifespan, and misc interactive
self_male.lifespan = self_data.lifespan*1.2
self_male.lung_capacity = 25
self_male.sex = "male"
-- remove interactive from female to get api to re-register
self_male.rivals = nil
self_male.friends = nil
-- unique predator + player interactions
self_male.predator_interactions = 0.02 --NotPegasun (run away!)
self_male.player_interaction = 0.01 --NotPegasun (run away!)
-- male functions
self_male.on_rightclick = function(self, clicker, time_from_last_click,
                                   tool_capabilities)
    if animals.stun_catch_mob(self, clicker, time_from_last_click,
                              tool_capabilities) then -- attack kidnapper
        animals.fight_or_flight(self, clicker, nil, 1)
    end
end
-- sounds
self_male.sounds = {
    warn = {
        name = "animals_chichasa_warn",
        gain={0.5, 0.8},
        fade={0.5, 1.5},
        pitch={0.9, 1.1},
        max_hear_distance = 50
    },
    scared = {
        name = "animals_chichasa_scared",
        gain={0.3, 0.4},
        fade={0.5, 1.5},
        pitch={1.2, 1.3},
    },
    call = {
        name = "animals_chichasa_call",
        gain={0.2, 0.5},
        fade={0.5, 1.5},
        pitch={0.9, 1.1},
    },
    mating = {
        name = "animals_chichasa_mate",
        gain={0.5, 0.9},
        fade={0.5, 1.5},
        pitch={1.2,1.5}--{0.8, 1.2},
    },
    attack = {
        name = "animals_chichasa_attack",
        gain={0.6, 0.8},
        fade={0.5, 1.5},
        pitch={0.7, 1.1},
    },
    punch = {
        name = "animals_punch",
        gain={0.5, 1.5},
        fade={0.5, 1.5},
        pitch={0.5, 1.5},
    },
}

-- male spawnegg or live animal modifications
self_male.spawnegg.description = nil -- handled in spawnegg registration
self_male._desc = S("Male Chichasa")
-- registering male
animals.register_animal(self_male.name,self_male)
