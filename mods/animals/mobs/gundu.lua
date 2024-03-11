----------------------------------------------------------------------
-- Gundu
--a small fish
--[[
filter feeds in sunlit waters
]]
---------------------------------------------------------------------

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor

local function pos_is_liquid(pos)
	local node=mobkit.nodeatpos(pos)
	if node and node.drawtype ~= 'liquid' then
		return false
	else 
		return true
	end
end

-----------------------------------
local function brain(self)
	-- Make sure the block in front is liquid.
	local pos = mobkit.get_stand_pos(self)
	local yaw = self.object:get_yaw()
	local vel = self.object:get_velocity()

	local fpos = mobkit.pos_translate2d(pos,yaw,1) --front position
	local fu_pos = mobkit.pos_shift(fpos,{y=-1}) -- under front position
	local u_pos = mobkit.pos_shift(pos,{y=-1})  -- under possition

	if not pos_is_liquid(u_pos) or not pos_is_liquid(fu_pos) then
		-- no water below risie up
		vel.y = 0.2
		self.object:set_velocity(vel)
	end

	if not pos_is_liquid(fpos) then
		-- rise a little faster and turn
		vel.y = vel.y+0.2
		self.object:set_velocity(vel)
		mobkit.clear_queue_high(self)
		mobkit.hq_aqua_turn(self,68,yaw+2,2)
	end
  -- calculate instantanious effects
  animals.core_hp(self)

	if mobkit.timer(self,1) then
		-- Also recharges health from energy
		local age, energy = animals.core_life(self, pos)

		--die from exhaustion or age
		if not age then
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
				animals.flock(self, 21, 1, self.max_speed)
			elseif random() <0.15 then
				rival = animals.territorial_water(self, energy, false)
			elseif random() <0.01 then
				rival = animals.territorial_water(self, energy, true)
			elseif random() <0.25 then
				animals.flock(self, 15, 2, self.max_speed/2)
			end

			--feeding
			--in bright light, when no threats
			local light = minetest.get_node_light(pos) or 0
			local lightm = minetest.get_node_light(pos, 0.5) or 0
			if not pred and not rival then

				if light >= 9 then
					--much light much food
					if energy < self.energy_max then
						energy = energy + 5
					end

				elseif light >= 5 then
					--some light
					if energy < self.energy_max then
						energy = energy + 2
					end
				end
			end

			--movement
			local tod = minetest.get_timeofday()

			if tod <0.06 or tod >0.94 then
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


			--reproduction
			--asexual parthogenesis, eggs
			--no threats, darkness, peak condition
			if (random() < 0.03)
			and not rival
			and not pred
			and lightm <= 11
			and ( tod <0.5 ) -- only lay at night
			and self.hp >= self.max_hp
			and energy >= (self.energy_max * 0.99) then
				energy = animals.place_egg(self, pos, energy, 'nodes_nature:salt_water_source')
			end

		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'def')
			mobkit.hq_aqua_roam(self,10,1)
		end


		-----------------
		--housekeeping
		--save energy, age
		mobkit.remember(self,'energy',energy)
		mobkit.remember(self,'age',age)

	end
end






---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF GUNDU INTERACTOR SETTINGS
animals.add_interactors("animals:gundu","predators", "animals:sarkamos", "animals:darkasthaan")
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

   -- animal stats
	lung_capacity = 5,
  -- comfort temps
	min_temp = -2,
	max_temp = 42,
  -- is it land-borne (1), sea-borne (2), or amphibious (3)?
  class = 2,
  -- energy
  energy_max = 8000,--secs it can survive without food
  energy_egg = "energy_max*.5", -- energy that goes to egg
  egg_timer = 60*32,
  young_per_egg = {3,7},		--will get this/energy_egg starting energy
  -- lifespan
  lifespan = "energy_max*6",
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
	max_speed = 5,					-- m/s
	jump_height = 1.5,				-- nodes/meters
	view_range = 5,					-- nodes/meters
	--attack
	attack={range=0.3, damage_groups={fleshy=1}},
	armor_groups = {fleshy=100},
  --on actions
	drops = {
		{name = "animals:carcass_fish_small", chance = 1, min = 1, max = 1,},
	},
	on_rightclick = function(self, clicker, time_from_last_click, tool_capabilities)
		animals.stun_catch_mob(self, clicker, time_from_last_click, tool_capabilities)
    animals.fight_or_flight(self, clicker)
	end,
  -- egg
  egg = {
    name = "animals:gundu_eggs",
    description = S('Gundu Eggs'),
    tiles = {"animals_gundu_eggs.png"},
    stack_max = minimal.stack_max_bulky,
    groups = {snappy = 3, edible = 1, egg = 3},
    drawtype = "normal",
    nodebox = nil,
    _medium = 'nodes_nature:salt_water_source',
    _replace = 'nodes_nature:salt_water_flowing',
  },
  -- spawnegg or live animal
  spawnegg = {
    desc = S("Live Gundu"),
    inv_img = "animals_gundu_item.png",
    stack = minimal.stack_max_medium/2
  },
}
animals.register_animal("animals:gundu",self_data)
