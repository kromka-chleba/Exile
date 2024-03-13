HEALTH = HEALTH
player_api = player_api

HEALTH.internal_temp_table = {
   [0] = { h_adj = 0, r_adj = 0, mov_adj = 0 },
	--37-38: normal
   [1] = { h_adj = -4, r_adj = -8, mov_adj = -20 },
	--32-36: hypothermia. malus
	--38-43: hyperthermia. malus.
   [2] = { h_adj = -8, r_adj = -32, mov_adj = -40 },
	--26-31: severe hypo. malus no heal
	--43-47: severe heat stroke. malus no heal
   [3] = { h_adj = -16, r_adj = -64, mov_adj = -80 },
	--<27 death
	-->47 death
   [4] = { h_adj = -10000, r_adj = -10000, mov_adj = -10000 }
        --immediate death
}

-- Example state, used to translate core temperature into a severity on above
--  Nothing is saved at the moment
-- #TODO: translate illnesses into states
player_api.register_state({
	 mod = "health",
	 name = "int_temp",
	 priority = 1,
	 -- optional entries below
	 id = 1, -- numeric id, unique count per mod, might be removed later
	 threshold = { [0] =  0, 26, 31, 36, 38, 44, 47, 100}, -- read -4
	 --label = "body temp",
	 -- ^^ invisible state. Display uses basic states instead, as example
	 severity_txt = {
	    [0] = "Caveman in ice", "Frozen", "Frostbitten", "Chilled",
	    "",
	    "Too warm", "Heat stroke", "Cooked", "Bones and ash" },
})

player_api.register_state({
      mod = "health",
      name = "energy",
      priority = 1,
      id = 2,
      threshold = { [0] =  200, 400, 600, 800 }, -- default * 10
      label = "-", -- Display severity only
      severity_txt = { [0] = "Exhausted", "Weary", "Tired", "", "Well-rested" },
})

player_api.register_state({
      mod = "health",
      name = "hunger",
      priority = 1,
      id = 2,
      threshold = { [0] =  200, 400, 600, 800 }, -- default * 10
      label = "-", -- Display severity only
      severity_txt = { [0] = "Starving", "Thin", "", "", "Well-fed" },
})

player_api.register_state({
      mod = "health",
      name = "thirst",
      priority = 1,
      id = 2,
      label = "-", -- Display severity only
      severity_txt = { [0] = "Dying of thirst", "Very thirsty",
	 "Thirsty", "", "" },
})

player_api.register_state({
      mod = "health",
      name = "resting",
      priority = 1,
      id = 2,
      label = "Resting", -- Display severity only
      severity = 2,
      severity_txt = { [0] = "(Shivering)", "poorly", "",
	 "comfortably", "(Sweating)" },
})
