---------------------------------------------------------------------
-- Gundu
--a small fish
--[[
    filter feeds in sunlit waters
]]
---------------------------------------------------------------------

animals = animals
mobkit = mobkit

-- Internationalization
local S = animals.S

local random = math.random


local function drawtype(pos)
    local node=mobkit.nodeatpos(pos)
    return node and node.drawtype or ''
end

-- If `self` is descending according to its current velocity `vel` `pull_up()`.
-- `vel_inc_y` will be added anyways, but the result will be limited to a max.
-- of vel.y = +1m/s. Finally the result is set as new velocity of `self`.
-- use cases: e.g. avoid diving into nodes with air
function pull_up(self, vel, vel_inc_y)
    -- just adding increments to vel.y sometimes is not enough
    if vel.y < 0 then vel.y = 0.5 * vel.y end  -- vel.y < -1.5 is possible
    vel.y = vel.y + vel_inc_y                -- accelerate vertically
    if vel.y > 1 then vel.y = 1 end  -- do not kick them out of the water
    self.object:set_velocity(vel)
end

-- `avoid_bad_nodes()`: Apply a strategy for Gundus to avoid swimming into non-
-- liquid nodes, especially air nodes and nodes with air pockets. Also to avoid
-- collisions with solid nodes. NOTE: Success rate depends on their speed and
-- on how this function gets called. But calling it every step is expensive and
-- causes Gundus to hover above the water.
local function avoid_bad_nodes(self)
    -- check entity's state first, before accessing the map
    local vel = self.object:get_velocity()
    local check_ground = vel.y < 0.2  -- potentially sinking before next check
    -- hor. speed > 0.1 m/s? (usually 0.0 at night)
    local hor_speed_sqr = vel.x * vel.x + vel.z * vel.z
    local check_obstacle = hor_speed_sqr > 0.01
    if not (check_obstacle or check_ground) then return end
    -- Otherwise and if not already in air -> rise up.
    local pos = mobkit.get_stand_pos(self)
    local in_air = (drawtype(pos) == 'airlike')
    if in_air then return end  -- above water level or too late to avoid

    local yaw = self.object:get_yaw()
    local fpos = mobkit.pos_translate2d(pos, yaw, 1) --front position

    if check_obstacle then
        -- NOTE: Gundus almost always move forward.
        if (drawtype(fpos) ~= 'liquid') then
            -- obstacle ahead -> rise a little faster and turn
            pull_up(self, vel, 0.4)
            mobkit.clear_queue_high(self)
            local hor_speed = math.min(math.sqrt(hor_speed_sqr), 1)
            mobkit.hq_aqua_turn(self, 68, yaw + 2, hor_speed)
            return  -- no need to check the ground, too
        end
    end

    -- in general: keep a safe distance from the ground ahead
    if check_ground then
        if check_obstacle then
            local under_front = vector.new(fpos.x, fpos.y - 1, fpos.z)
            if drawtype(under_front) ~= 'liquid' then
                pull_up(self, vel, 0.2)
                return
            end
        end
        local under_pos = vector.new(pos.x, pos.y - 1, pos.z)
        if drawtype(under_pos) ~= 'liquid' then
            pull_up(self, vel, 0.2)
        end
    end
end

-----------------------------------
local function brain(self)
    -- Make sure the block in front is liquid (not air, glass, flowing liquid,
    -- ...). Checking every step cannot make it 100% failsafe if the server
    -- thread hangs for too long and the fish passes more than 1 node in one
    -- step. max_speed is 5 nodes/s but checking 5 times/sec is not enough,
    -- since then a Gundu might already have passed 100% of the node since last
    -- check and hq_turn_aqua() will not make it turn on the spot.
    local speed = self.object:get_velocity():length()
    local dt = math.min(0.5, 0.2 / speed) -- at 5m/s 25 checks/s must be enough
    if animals.timer(self, dt) then
        avoid_bad_nodes(self)
    end

    -- calculate instantanious effects
    animals.core_hp(self)

    if mobkit.timer(self,1) then
        -- Also recharges health from energy
        --die from exhaustion or age
        local pos = mobkit.get_stand_pos(self)
        if not animals.core_life(self, pos) then
            return
        end


        local prty = mobkit.get_queue_priority(self)
        -------------------
        --High priority actions
        local pred = nil

        if prty < 50 then
            --Threats
            local plyr = animals.get_nearby_player(self)
            if plyr then
                animals.fight_or_flight(self, plyr)
            end

            pred = animals.predator_avoid(self)

            --Return to water
            if not self.isinliquid then
                mobkit.clear_queue_high(self)
                animals.hq_swimfrompos(self,66,pos,1)
            end
            -- Temp out of range
            local temp = climate.get_point_temp(pos, true)
            if not animals.temp_comfy(self,temp) then
                local vel = self.object:get_velocity()
                vel.y = vel.y-0.2
                self.object:set_velocity(vel)
                mobkit.hq_aqua_roam(self,10,0.2)
            end

        end


        ----------------------
        --Low priority actions
        if prty < 20 then

            --social behaviour
            local rival
            if pred then
                animals.flock(self, 21, self.view_range/2, 2, self.max_speed)
            elseif random() <0.15 then
                rival = animals.territorial(self, false)
            elseif random() <0.01 then
                rival = animals.territorial(self, true)
            elseif random() <0.25 then
                animals.flock(self, 15, 2, self.max_speed/2)
            end

            local tod = animals.timeofday()
            local light = minetest.get_node_light(pos) or 0
            local lightm = minetest.get_node_light(pos, 0.5) -- daylight level
                or 0
            -- pred-less, rival-less activities
            if not pred and not rival then
                -- no pred, no rivals
                --feeding
                --in bright light, when no threats
                if self.energy < self.energy_max and light >= 5 then
                    -- feeding
                    local yield = 1 -- some light
                    if light >= 12 then
                        -- so so much light big yummy
                        yield = 3
                    elseif light >= 9 then
                        -- many light
                        yield = 2
                    end
                    self:modify('energy',yield)
                end
                --reproduction
                --asexual parthogenesis, eggs
                --no threats, darkness, peak condition
                if random() < 0.1
                    and lightm <= 11
                    and tod == "night" -- lay at night
                    and self.hp >= self.max_hp
                    and self.energy >= (self.energy_max * 0.99) then
                    animals.place_egg(self, pos)
                end
            end

            --movement
            if tod == "night" then
                --sink at night to lay eggs
                local vel = self.object:get_velocity()
                vel.y = vel.y-0.2
                self.object:set_velocity(vel)
                mobkit.hq_aqua_roam(self,10,0.2)

            elseif light <= 9 then
                --rise during day if not in best light
                local vel = self.object:get_velocity()
                vel.y = vel.y+0.2
                self.object:set_velocity(vel)
                mobkit.hq_aqua_roam(self,10, random(1, self.max_speed))

            else
                --no special movement
                mobkit.hq_aqua_roam(self,5, random(0.5, self.max_speed/2))

            end
        end

        -------------------
        --generic behaviour
        if mobkit.is_queue_empty_high(self) then
            animals.animate(self,'def')
            mobkit.hq_aqua_roam(self,10,1)
        end
    end
end






---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF GUNDU INTERACTOR SETTINGS
animals.add_interactors("animals:gundu","predators",
                        "animals:sarkamos", "animals:darkasthaan", "animals:kubwakubwa")
animals.add_interactors("animals:gundu","rivals", "self")
animals.add_interactors("animals:gundu","friends", "self")

----------------------------------------------
--Animal Data

local self_data = {
    name = "animals:gundu",
    initial_properties = {
        --core
        max_hp = 10,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.3, -0.2, -0.3, 0.3, 0.1, 0.3},
        visual = "mesh",
        mesh = "animals_gundu.b3d",
        textures = {"animals_color_palette.png"},
        visual_size = {x = 5, y = 5},
        makes_footstep_sound = false,
    },
    _name = "Gundu",
    _desc = S("Gundu"),

    -- animal stats
    lung_capacity = 5,
    -- comfort temps
    min_temp = -2,
    max_temp = 42,
    -- is it land-borne (1), sea-borne (2), or amphibious (3)?
    class = 2,
    -- energy
    energy_max = 8000,--secs it can survive without food
    energy_egg = "energy_max*.82", -- energy that goes to egg
    egg_time = 60*32,
    young_per_egg = {4,10}, --will get this/energy_egg starting energy
    -- lifespan
    lifespan = "energy_max*3",
    -- interactions
    -- rivals + friends automatically defined in registration
    consume_non_prey = false,
    player_interaction = 0,
    predator_interactions = 0,
    capture_interactions = {
        club = 0.15,
        hand = 0.05,
    },
    -- logic for mobkit
    logic = brain,
    -- animations + sounds
    animation = {
        def={range={x=1,y=20},speed=20,loop=true},
        fast={range={x=20,y=40},speed=40,loop=true},
        stand={range={x=40,y=60},speed=20,loop=true},
        dead = {range ={x=0, y=0},speed = 0,loop=false},
    },
    sounds = {
        flee = {
            name = "animals_water_swish",
            gain={0.5, 1.5},
            fade={0.5, 1.5},
            pitch={0.5, 1.5},
        },
        call = {
            name = "animals_gundu_call",
            gain={0.05, 0.15},
            fade={0.5, 1.5},
            pitch={0.6, 1.2},
        },
        punch = {
            name = "animals_punch",
            gain={0.5, 1},
            fade={0.5, 1.5},
            pitch={0.5, 1.5},
        },
    },
    --movement
    springiness=0.5,
    buoyancy = 1,
    max_speed = 5,                                       -- m/s
    jump_height = 1.5,                           -- nodes/meters
    view_range = 5,                                      -- nodes/meters
    --attack
    attack={range=0.3, damage_groups={fleshy=1}},
    armor_groups = {fleshy=100},
    --on actions
    drops = "animals:carcass_fish_small",
    on_rightclick = function(self, clicker, time_from_last_click,
                             tool_capabilities)
        animals.stun_catch_mob(self, clicker, time_from_last_click,
                               tool_capabilities)
        animals.fight_or_flight(self, clicker)
    end,
    -- egg
    egg = {
        tiles = {"animals_gundu_eggs.png"},
        stack_max = minimal.stack_max_bulky,
        groups = {egg = 3},
        drawtype = "normal",
        egg_medium = 'nodes_nature:salt_water_source',
        egg_replace = 'nodes_nature:salt_water_flowing',
    },
    -- spawnegg or live animal
    spawnegg = {
        stack_max = minimal.stack_max_medium/2
    },
}
animals.register_animal("animals:gundu",self_data)
