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
  -- calculate instantanious effects
  animals.core_hp(self)
  
	if mobkit.timer(self,1) then
		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, pos)
		--die from exhaustion or age
		if not age then
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
				animals.fight_or_flight(self, plyr, 55, 0.01)
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
            if (animals.eat_flora(pos,0.001) == true) then
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
  -- calculate instantanious effects
  animals.core_hp(self)
  
	if mobkit.timer(self,1) then
		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, pos)
		--die from exhaustion or age
		if not age then
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
				animals.fight_or_flight(self, plyr, 55, 0.6)
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
        if (animals.eat_flora(pos,0.0005) == true) then -- mmm plants
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
animals.add_interactors("animals:pegasun","predators", "animals:kubwakubwa", "animals:darkasthaan", "animals:sarkamos")
animals.add_interactors("animals:pegasun","prey", "animals:sneachan", "animals:impethu")
animals.add_interactors("animals:pegasun","friends", "self","animals:pegasun_male")
animals.add_interactors("animals:pegasun","rivals", "self")

-- MALE INTERACTORS
animals.add_interactors("animals:pegasun_male","friends", "animals:pegasun")
animals.add_interactors("animals:pegasun_male","rivals", "self")

------------------------------------------------------------------------
--FEMALE
local self_data = {
  initial_properties = {
    max_hp = 40,
    
    collisionbox = {-0.16, -0.75, -0.16, 0.16, -0.25, 0.16},
    visual = "mesh",
    mesh = "animals_pegasun.b3d",
    textures = {"animals_pegasun.png"},
    visual_size = {x = 1, y = 1},
  },
  -- animal stats
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
  egg_timer = 60*25,
  young_per_egg = 1,		--will get this/energy_egg starting energy
  -- lifespan
  lifespan = "energy_max*10",
  mature_age = "energy_max*0.36", -- 36% of energy_max (8000) or 2880
  -- interactions
  -- predators + rivals automatically defined in registration
  capture_interactions = {
    club = 0.35,
  },
  sex = "female",
  -- logic for mobkit
  logic = brain,
  -- animations + sounds
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
  --on actions
	drops = {
		{name = "animals:carcass_bird_small", chance = 1, min = 1, max = 1,},
	},
	on_rightclick = function(self, clicker)
		animals.stun_catch_mob(self, clicker)
    animals.fight_or_flight(self, clicker) -- ewww a human touched me!!!
	end,
  -- egg
  egg = {
    name = "animals:pegasun_eggs",
    description = S('Pegasun Egg'),
    tiles = {"animals_gundu_eggs.png"},
    stack_max = minimal.stack_max_medium,
    node_box = {
      type = "fixed",
      fixed = {-0.125, -0.5, -0.125,  0.125, -0.125, 0.125},
    },
    groups = {egg = 2},
    _hatching = {
      ["animals:pegasun"] = 0.5,
      ["animals:pegasun_male"] = 0.5,
    },
  },
  -- spawnegg or live animal
  spawnegg = {
    desc = S("Live Pegasun"),
    inv_img = "animals_pegasun_item.png",
    stack = minimal.stack_max_medium
  }
}
self_data = animals.register_animal("animals:pegasun",self_data)
local self_male = table.copy(self_data)
self_male.name = "animals:pegasun_male"
-- don't register egg again for male
self_male.egg = nil
-- modifications for males
-- initial properties
self_male.logic = brain_male
self_male.initial_properties.max_hp = 45
self_male.initial_properties.textures = {"animals_pegasun_male.png"}
-- sexual dimorphism, male bigger then female
for index,data in pairs(self_male.initial_properties) do
  if index == "collisionbox" or index == "visual_size" then
    for index2,value in pairs(data) do
      if type(value) == "number" then
        data[index2] = value*1.15 -- size increase by 15%
      end
    end
  end
end
-- physical properties
self_male.max_speed = 2.5
self_male.jump_height = 1.5
-- male energy, lifespan, and misc interactive
self_male.lifespan = self_data.lifespan*1.2
self_male.lung_capacity = 25
self_male.sex = "male"
-- remove interactive from female to get api to re-register
self_male.rivals = nil
self_male.friends = nil
-- male functions
self_male.on_rightclick = function(self, clicker)
  if animals.stun_catch_mob(self, clicker) then -- attack kidnapper
    animals.fight_or_flight(self, clicker, nil, 1)
  end
end
-- sounds
self_male.sounds = {
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
}
-- attack
self_male.attack={range=0.5, damage_groups={fleshy=4}}
-- male spawnegg or live animal modifications
self_male.spawnegg.desc = S("Live Male Pegasun")
-- registering male
animals.register_animal(self_male.name,self_male)