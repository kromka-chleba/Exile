----------------------------------------------------------------------
-- Pegasun
--chicken like bird
--[[
males and females, must mate to reproduce.
lives off flora, spreading surface and insects
]]
---------------------------------------------------------------------

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor

-----------------------------------
local function brain(self)
	if mobkit.timer(self,1) then
    
		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, self.lifespan, pos)
		--die from exhaustion or age
		if not age then
			return
		end
    
		------------------
		--Emergency actions

		--swim to shore
		if self.isinliquid then
			mobkit.hq_liquid_recovery(self,60)
		end


		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		if prty < 50 then


			--Threats
			local plyr = animals.get_nearby_player(self)
			if plyr then
				animals.fight_or_flight_plyr(self, plyr, 55, 0.01)
			end

			animals.predator_avoid(self, 55, 0.01)


		end


		----------------------
		--Low priority actions
		if prty < 20 then


			--random choice between
			--feeding, exploring, social
			--chance differs by time
			local ce = 0.1
			local cs = 0.1
			-- c feeding is simply what happens if no
			--others are selected
			local tod = minetest.get_timeofday()
			if tod <0.2 or tod >0.8 then
				--more social at night
				ce = 0.01
				cs = 0.75
			elseif tod >0.55 and tod <0.55 then
				--explore during midday
				ce = 0.5
				cs = 0.1
			end


			if random() < ce then
				if random() < 0.95 then
					--wander random
					mobkit.animate(self,'walk')
					mobkit.hq_roam(self,10)
				else
					--wander temp
					mobkit.animate(self,'walk')
					animals.hq_roam_comfort_temp(self,12, 21)
				end

			elseif random() < cs then

				--social
				if random()< 0.3 then
					animals.flock(self, 25, 3)
				elseif random()< 0.01 then
					animals.territorial(self, energy, false)
				elseif random() < 0.1 and age >= self.mature_age then

					--reproduction
					if self.hp >= self.max_hp
					and energy >= (self.energy_egg * 1.5) then

						--are we already pregnant?
						local preg = mobkit.recall(self,'pregnant') or false
						if preg == true then
							mobkit.lq_idle(self,3)
							if random() < 0.05 then
								energy = animals.place_egg(self, pos, energy)
								mobkit.remember(self,'pregnant',false)
							end

						else

							--we are randy
							mobkit.remember(self,'sexual',true)
							local mate = animals.mate_assess(self, 'animals:pegasun_male')
							if mate then
								--go get him!
								mobkit.make_sound(self,'mating')
								if random() < 0.5 then
									animals.hq_mate(self, 25, mate)
								end
							end
						end
					else
						--I'm too tired darling
						mobkit.remember(self,'sexual',false)
					end
				end

			elseif energy < self.energy_max then
        local hng_percent = (self.energy_max * 0.55)/energy -- hunger_percent - creates a percentage by dividing a percentage of energy_max by the current energy. The lower the energy, the higher the percentage
        -- if energy is equal or less than 55% of energy_max, it will be 1 or higher
        
        if (random() <= hng_percent) then
          -- females much hungrier and predatory than males (gotta fill up for those babies y'know)
          if not (random() <= 0.85 and animals.prey_hunt(self,30)) then
            if (animals.eat_flora(pos,0.01) == true) then
              energy = energy + 50
            else
              mobkit.animate(self,'walk')
              -- look for flora that's not a cane_plant
              animals.hq_roam_walkable_group(self, 'flora', "cane_plant", 15) -- self, go for group, ignore group, priority
            end
          end
        else
          mobkit.animate(self,'walk')
          mobkit.hq_roam(self,10)
        end
			end

		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			mobkit.hq_roam(self,10)
		end

		-----------------
		--housekeeping
		--save energy, age
		mobkit.remember(self,'energy',energy)
		mobkit.remember(self,'age',age)

	end
end





-----------------------------------
--MALE BEHAVIOUR
local function brain_male(self)
	if mobkit.timer(self,1) then

		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, self.lifespan, pos)
		--die from exhaustion or age
		if not age then
			return
		end


		------------------
		--Emergency actions

		--swim to shore
		if self.isinliquid then
			mobkit.hq_liquid_recovery(self,60)
		end


		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		if prty < 50 then


			--Threats
			local plyr = animals.get_nearby_player(self)
			if plyr then
				animals.fight_or_flight_plyr(self, plyr, 55, 0.6)
			end

			animals.predator_avoid(self, 55, 0.8)

		end


		----------------------
		--Low priority actions

		if prty < 20 then


			--random choice between
			--feeding, exploring, social
			--chance differs by time
			local ce = 0.2
			local cs = 0.4
			-- c feeding is simply what happens if no
			--others are selected
			local tod = minetest.get_timeofday()
			if tod <0.2 or tod >0.8 then
				--more social at night
				ce = 0.01
				cs = 0.95
			elseif tod >0.55 and tod <0.55 then
				--explore during midday
				ce = 0.6
				cs = 0.2
			end


			if random() < ce then
				if random() < 0.95 then
					--wander random
					mobkit.animate(self,'walk')
					mobkit.hq_roam(self,10)
				else
					--wander temp
					mobkit.animate(self,'walk')
					animals.hq_roam_comfort_temp(self,10, 21)
				end

			elseif random() < cs then

				--social
				if random()< 0.5 then
					animals.flock(self, 25, 1)
				elseif random()< 0.85 then
					animals.territorial(self, energy, false)
				elseif random() < 0.3 and age >= self.mature_age then -- males more promiscuous (from 0.1 to 0.3)

					--reproduction
					if self.hp >= self.max_hp
					and energy >= self.energy_max * 0.25 then -- mate at 25% of energy_max (8000 * 0.25 = 2000)
						--set status as randy
						--find nearby prospect and try to mate
						mobkit.remember(self, 'sexual', true)
						local mate = animals.mate_assess(self, 'animals:pegasun')

						if mate then
							--go get her!
							mobkit.make_sound(self,'mating')
							if random() < 0.5 then
                energy = energy - 1000 -- energy use for mating lol
								animals.hq_mate(self, 25, mate)
							end
						end

					else
						--in no state for hankypanky
						mobkit.remember(self, 'sexual', false)
					end
				end

    elseif energy < self.energy_max then
      local hng_percent  = (self.energy_max * 0.2)/energy -- hunger_percent
      -- if energy is equal or less than 20% of energy_max, it will be 1 or higher
      
      if (random() <= hng_percent ) then
        --feed via a method
        if (animals.eat_flora(pos,0.005) == true) then -- mmm plants
          energy = energy + 50
        elseif not (random() <= 0.5 and animals.prey_hunt(self,30)) then
          --wander randomly for plants if can't find prey
            mobkit.animate(self,'walk')
            animals.hq_roam_walkable_group(self, 'flora', "cane_plant", 15) -- go for group, ignore group, priority
        end
      else
        mobkit.animate(self,'walk')
        mobkit.hq_roam(self,10)
      end
    end

		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			mobkit.hq_roam(self,10)
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
-- SETTING OF PEGASUN INTERACTOR SETTINGS
animals.add_interactors("predators","pegasun","animals:kubwakubwa", "animals:darkasthaan", "animals:sarkamos")
animals.add_interactors("prey","pegasun","animals:sneachan", "animals:impethu")
animals.add_interactors("friends","pegasun","animals:pegasun", "animals:pegasun_male")
animals.add_interactors("rivals","pegasun","animals:pegasun")

-- MALE INTERACTORS
animals.add_interactors("friends","pegasun_male","animals:pegasun")
animals.add_interactors("rivals","pegasun_male","animals:pegasun_male")

------------------------------------------------------------------------
--FEMALE
local self_data = {
  name = "animals:pegasun",
	--core
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.16, -0.75, -0.16, 0.16, -0.25, 0.16},
	visual = "mesh",
	mesh = "animals_pegasun.b3d",
	textures = {"animals_pegasun.png"},
	visual_size = {x = 1, y = 1},
	makes_footstep_sound = true,
	timeout = 0,

	-- animal stats
	max_hp = 40,
	lung_capacity = 20,
  energy_loss = 1,
  -- comfort temps
	min_temp = -24,
	max_temp = 46,
  -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
  class = 1,

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain,
	-- optional mobkit props
	-- or used by built in behaviors
	--physics = [function user defined] 		-- optional, overrides built in physics
	animation = {
		walk={range={x=71, y=90}, speed=24, loop=true},
		fast={range={x=91, y=110}, speed=24, loop=true},
		stand={
			{range={x=1, y=31}, speed=28, loop=true},
			{range={x=31, y=70}, speed=32, loop=true},
		},
    dead = { range = {x=0, y=0}, speed = 0, loop=true},
	},
	sounds = {
		warn = {
			name = "animals_pegasun_warn",
			gain={0.2, 0.5},
			fade={0.5, 1.5},
			pitch={0.9, 1.1},
		},
		scared = {
			name = "animals_pegasun_scared",
			gain={0.2, 0.3},
			fade={0.5, 1.5},
			pitch={1.3, 1.4},
		},
		call = {
			name = "animals_pegasun_call",
			gain={0.2, 0.4},
			fade={0.5, 1.5},
			pitch={0.9, 1.1},
		},
		mating = {
			name = "animals_pegasun_warn",
			gain={0.4, 0.7},
			fade={0.5, 1.5},
			pitch={1.2,1.7}--{0.9, 1.4},
		},
		attack = {
			name = "animals_pegasun_attack",
			gain={0.4, 0.7},
			fade={0.5, 1.5},
			pitch={0.9, 1.4},
		},
		punch = {
			name = "animals_punch",
			gain={0.5, 1.5},
			fade={0.5, 1.5},
			pitch={0.5, 1.5},
		},
	},

	--movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 2,					-- m/s
	jump_height = 1.2,				-- nodes/meters
	view_range = 7,					-- nodes/meters

	--attack
	attack={range=0.3, damage_groups={fleshy=2}},
	armor_groups = {fleshy=100},
  
  --interaction
	predators = animals.get_interactors("pegasun","predators"),
	prey = animals.get_interactors("pegasun","prey"),
	friends = animals.get_interactors("pegasun","friends"),
	rivals = animals.get_interactors("pegasun","rivals"),

	--on actions
	drops = {
		{name = "animals:carcass_bird_small", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.05)
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		animals.stun_catch_mob(self, clicker, 0.25)
	end,
}
-- energy and eggs
self_data.energy_max = 8000   --secs it can survive without food
self_data.energy_egg = self_data.energy_max/2  --energy that goes to egg
self_data.egg_timer = 60*25
self_data.young_per_egg = 1   --will get this/energy_egg starting energy
-- lifespan
self_data.lifespan = self_data.energy_max * 10
self_data.mature_age = self_data.energy_max * 0.36 -- 36% of energy_max (8000) or 2880
---------------------;
minetest.register_entity("animals:pegasun",self_data)

--spawn egg (i.e. live animal in inventory)
animals.register_egg("animals:pegasun", S("Live Pegasun (female)"), "animals_pegasun_item.png", minimal.stack_max_medium, self_data)

----------------------------------------------
--THE MALE
local self_male = {
  name = "animals:pegasun_male",
	--core
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.16, -0.75, -0.16, 0.16, -0.25, 0.16},
	visual = "mesh",
	mesh = "animals_pegasun.b3d",
	textures = {"animals_pegasun_male.png"},
	visual_size = {x = 1, y = 1},
	makes_footstep_sound = true,
	timeout = 0,

	-- animal stats
	max_hp = 45,
	lung_capacity = 25,
  energy_loss = self_data.energy_loss,
  -- comfort temps
	min_temp = self_data.min_temp,
	max_temp = self_data.max_temp,
  
  

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain_male,
	-- optional mobkit props
	-- or used by built in behaviors
	--physics = [function user defined] 		-- optional, overrides built in physics
	animation = {
		walk={range={x=71, y=90}, speed=24, loop=true},
		fast={range={x=91, y=110}, speed=24, loop=true},
		stand={
			{range={x=1, y=0}, speed=28, loop=true},
			{range={x=31, y=0}, speed=32, loop=true},
		},
		dead = { range={x=0, y=0}, speed=0, loop=true},
	},
	sounds = {
		warn = {
			name = "animals_pegasun_warn",
			gain={0.3, 0.6},
			fade={0.5, 1.5},
			pitch={0.9, 1.1},
		},
		scared = {
			name = "animals_pegasun_scared",
			gain={0.3, 0.4},
			fade={0.5, 1.5},
			pitch={1.2, 1.3},
		},
		call = {
			name = "animals_pegasun_call",
			gain={0.2, 0.5},
			fade={0.5, 1.5},
			pitch={0.9, 1.1},
		},
		mating = {
			name = "animals_pegasun_warn",--"animals_pegasun_mate"
			gain={0.5, 0.9},
			fade={0.5, 1.5},
			pitch={1.2,1.5}--{0.8, 1.2},
		},
		attack = {
			name = "animals_pegasun_attack",
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
	},

	--movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 2.5,					-- m/s
	jump_height = 1.5,				-- nodes/meters
	view_range = 7,					-- nodes/meters

	--attack
	attack={range=0.5, damage_groups={fleshy=4}},
	armor_groups = {fleshy=100},
  
  --interaction
	predators = animals.get_interactors("pegasun","predators"), -- use base pegasun predators
	prey = animals.get_interactors("pegasun","prey"), -- use base pegasun prey
	friends = animals.get_interactors("pegasun_male","friends"),
	rivals = animals.get_interactors("pegasun_male","rivals"),
	sex = "male",

	--on actions
	drops = {
		{name = "animals:carcass_bird_small", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.6)
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		animals.stun_catch_mob(self, clicker, 0.15)
	end,
}
-- energy and eggs
self_male.energy_max = self_data.energy_max
-- lifespan
self_male.lifespan = self_data.lifespan * 1.2 -- if the flock male dies they go extinct
self_male.mature_age = self_data.mature_age
---------------------;
minetest.register_entity("animals:pegasun_male",self_male)

--spawn egg (i.e. live animal in inventory)
animals.register_egg("animals:pegasun_male", S("Live Pegasun (male)"), "animals_pegasun_item.png", minimal.stack_max_medium, self_data )

----------------------------------------------
--eggs
minetest.register_node("animals:pegasun_eggs", {
	description = S('Pegasun Egg'),
	tiles = {"animals_gundu_eggs.png"},
	stack_max = minimal.stack_max_medium,
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.125, -0.5, -0.125,  0.125, -0.125, 0.125},
	},
	groups = {snappy = 3, falling_node = 1, dig_immediate = 3, flammable = 1,  temp_pass = 1, edible = 1, egg = 2},
	sounds = nodes_nature.node_sound_defaults(),
	on_construct = function(pos)
    local egg_timer = self_data.egg_timer
		minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*2))
	end,
	on_timer =function(pos, elapsed)
		if random()<=0.5 then -- 50% for female, 50% for male
			return animals.hatch_egg(self_data, pos)
		else
			return animals.hatch_egg(self_data, pos, nil, nil, "animals:pegasun_male")
		end

	end,
})
