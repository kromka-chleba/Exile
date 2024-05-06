
--food_data.lua
--Contains data for all the predefined foods in Exile.
--[[Some notes:
	Calculating sensible values for food:
	(intervals/day) * hunger_rate = daily basal food needs
	i.e. 20 min/1 min * 2 = 40 units per day

	Therefore 40 units = 2,000 Calories.
	 calories -> units = 2,000/40 = 50 kcal/unit

	Sugar   3,900 kcal/kg = 78.0 units/kg  172.0 per lb.
	Bread   2,600 kcal/kg = 52.0 units/kg  115.0 per lb.
	Potato    750 kcal/kg = 15.0 units/kg   33.0 per lb.
	Meat    2,000 kcal/kg = 40.0 units/kg   88.0 per lb.
	cabbage   240 kcal/kg =  4.8 units/kg   10.5 per lb.
	]]--

HEALTH.food_table = {
	--name	     	      	               hp  th  hu   en  temp, replacewithitem (not implemented yet)
	["tech:maraka_bread_cooked"]        = {hu=24,en=14},
	["tech:maraka_bread_burned"]        = {hu=12,en=7},
	["tech:peeled_anperla_cooked"]      = {th=2,hu=12,en=7},
    ["nodes_nature:rzepicha_root"]      = {th=4,hu=35,en=5},
    ["nodes_nature:rzepicha_root_winter"]      = {th=4,hu=35,en=5},
	--example: burned anperla tubers are inedible, so no entry
	["tech:mashed_anperla_cooked"]      = {th=12,hu=72,en=42},
	["tech:mashed_anperla_burned"]      = {th=6,hu=36,en=21},
	["nodes_nature:sea_lettuce"]        = {hu=5,en=-10},
	["nodes_nature:sea_lettuce_cooked"] = {hu=5},
	["nodes_nature:vansano_seed"]       = {hu=1},
	["nodes_nature:tikusati_seed"]      = {hu=-2,en=2},
	--food and water                       hp  th   hu  en  te
        ["nodes_nature:wiha_fruitless"]     = {th=3,hu=1},
        ["nodes_nature:wiha_flowering"]     = {th=4,hu=2},
        ["nodes_nature:wiha_fruiting"]      = {th=8,hu=4},
        ["nodes_nature:wiha_fruit"]         = {th=4,hu=2},
        ["nodes_nature:jalowiec_cone"]      = {th=1,hu=1},
        ["nodes_nature:ziarnoplon_fruitless"]     = {th=3,hu=1},
        ["nodes_nature:ziarnoplon_flowering"]     = {th=2,hu=1,en=-6},
        ["nodes_nature:ziarnoplon_fruiting"]      = {th=3,hu=4,en=-4},
        ["nodes_nature:ziarnoplon_fruit"]         = {th=1,hu=1,en=-4},
        ["nodes_nature:srebroplon_fruitless"]     = {th=3,hu=1},
        ["nodes_nature:srebroplon_flowering"]     = {th=2,hu=1,en=-6},
        ["nodes_nature:srebroplon_fruiting"]      = {th=3,hu=4,en=-4},
        ["nodes_nature:srebroplon_fruit"]         = {th=1,hu=1,en=-4},
        ["nodes_nature:obesa_fruit"]        = {th=8,hu=1},
				["nodes_nature:muhle_fruit"]         = {hu=1},
        ["nodes_nature:malina_fruit"]       = {th=2,hu=4},
        ["nodes_nature:yellow_malina_fruit"]= {th=3,hu=4},
        ["nodes_nature:malinka_fruit"]      = {th=2,hu=2},
	    ["nodes_nature:zufani"]             = {hu=6},
        ["nodes_nature:zufani_fruit"]       = {hu=4,en=4},
        ["nodes_nature:damo_seedling1"]     = {th=1,hu=1},
        ["nodes_nature:damo_seedling2"]     = {th=1,hu=1},
        ["nodes_nature:damo_seedling3"]     = {th=1,hu=1},
        ["nodes_nature:damo_seedling4"]     = {th=1,hu=2},
        ["nodes_nature:damo_seedling5"]     = {th=1,hu=2},
				["nodes_nature:fretin_seedling1"]     = {hu=1, en=-1},
				["nodes_nature:fretin_seedling2"]     = {hu=1, en=-1},
				["nodes_nature:fretin_seedling3"]     = {hu=2, en=-2},
				["nodes_nature:fretin_seedling4"]     = {hu=3, en=-3},
				["nodes_nature:fretin_seedling5"]     = {hu=4, en=-4},
        ["nodes_nature:galanta_seedling1"]  = {th=1,hu=1},
        ["nodes_nature:galanta_seedling2"]  = {th=1,hu=1},
        ["nodes_nature:galanta_seedling3"]  = {th=1,hu=1},
        ["nodes_nature:galanta_seedling4"]  = {th=1,hu=2},
        ["nodes_nature:galanta_seedling5"]  = {th=1,hu=2},
        ["nodes_nature:galanta"]            = {th=1,hu=3},
	    ["nodes_nature:lambakap"]           = {th=10,hu=10},
	    ["nodes_nature:tangkal_fruit"]      = {th=5,hu=10,en=10},
	    ["nodes_nature:panasee_fruit"]      = {th=5,hu=4,en=1},
	    ["nodes_nature:amma_nut"]           = {hu=1,en=10},
	    ["nodes_nature:daoja_berry"]        = {hu=4},
        ["nodes_nature:momo_fruit"]         = {th=1,hu=12},
        ["nodes_nature:momo_fruiting"]      = {th=1,hu=15},
        ["nodes_nature:momo_fruitless"]     = {th=1,hu=3},
        ["nodes_nature:barszcz_fruit"]      = {th=1,hu=1},
        ["nodes_nature:barszcz_fruiting"]   = {th=1,hu=3},
        ["nodes_nature:barszcz_flowering"]  = {th=1,hu=2},
        ["nodes_nature:barszcz_fruitless"]  = {th=1,hu=2},
        ["nodes_nature:barszcz_root"]       = {th=1,hu=4,en=1},
	    ["nodes_nature:tsaplop"]            = {th=10,hu=10},
	    ["nodes_nature:snow"]               = {th=50,en=-100,temp=-1},
	    ["nodes_nature:snow_block"]         = {th=100,en=-200,temp=-2},
	--meat
     ["animals:carcass_invert_small"]       = {hu=3, en=-2},
     ["animals:carcass_invert_small_cooked"]= {hu=6,en=1},
     ["animals:carcass_invert_small_burned"]= {th=-1,hu=1,en=-3},
     ["animals:carcass_invert_large"]       = {th=1,hu=10,en=-6},
     ["animals:carcass_invert_large_cooked"]= {th=1,hu=20,en=3},
     ["animals:carcass_invert_large_burned"]= {th=-1,hu=2,en=-7},
     ["animals:carcass_bird_small"]         = {th=1,hu=20,en=-4},
     ["animals:carcass_bird_small_cooked"]  = {th=1,hu=40,en=2},
     ["animals:carcass_bird_small_burned"]  = {th=-1,hu=5,en=-5},
     ["animals:carcass_fish_small"]         = {th=1,hu=15,en=-4},
     ["animals:carcass_fish_small_cooked"]  = {th=2,hu=30,en=2},
     ["animals:carcass_fish_small_burned"]  = {th=-1,hu=5,en=-5},
     ["animals:carcass_fish_large"]         = {th=3,hu=45,en=-12},
     ["animals:carcass_fish_large_cooked"]  = {th=3,hu=90,en=6},
     ["animals:carcass_fish_large_burned"]  = {th=-1,hu=21,en=-13},
	--eggs
	["animals:darkasthaan_eggs"]        = {th=1,hu=10},
	["animals:gundu_eggs"]              = {th=10,hu=30},
	["animals:impethu_eggs"]            = {hu=4},
	["animals:kubwakubwa_eggs"]         = {hu=6},
	["animals:pegasun_eggs"]            = {hu=5},
	["animals:sarkamos_eggs"]           = {th=10,hu=40},
	["animals:sneachan_eggs"]           = {hu=3},
	--toxic
        ["nodes_nature:momo_flowering"]     = {th=1,hu=3},
        ["nodes_nature:wrotycz_fruit"]      = {hu=2},
	["nodes_nature:nebiyi"]             = {hu=1,en=-10},
	["nodes_nature:marbhan"]            = {hu=1,en=-10},
        ["nodes_nature:gevaari"]            = {hp=-2,hu=1,en=-10},
        ["nodes_nature:obesa_fruitless"]    = {hp=-2,th=10,hu=6,en=-4},
        ["nodes_nature:obesa_fruiting"]     = {hp=-2,th=10,hu=6,en=-4},
        ["nodes_nature:obesa_flowering"]    = {hp=-2,th=10,hu=6,en=-4},
	["nodes_nature:maraka_nut"]         = {hu=5,en=5},
	["nodes_nature:sasaran_cone"]       = {hu=1},
  --drugs
	["nodes_nature:tikusati"]           = {hu=-2,en=2},
  ["tech:tiku"]                       = {hu=-24,en=96},
  -- skulling an entire bucket, all energy and half food equivalent of the fruit
  ["tech:tang"]                       = {th=100,hu=60,en=180,rwi="tech:clay_water_pot",eat_sound=""},
  ["tech:wooden_tang"]                = {th=100,hu=60,en=180,rwi="tech:wooden_water_pot",eat_sound=""},
	--medicine                              hp  th   hu  en  te
	["nodes_nature:hakimi_flowering"]             = {hp=1,hu=1,en=-15},
	["nodes_nature:merki"]              = {hp=1,hu=1,en=-15},
  ["tech:herbal_medicine"]            = {hp=5},
	}

HEALTH.bake_table = {
	--name                          temp, duration, optional food value?
   ["tech:maraka_bread"]              = {temp=160,  duration=10 },
   ["tech:peeled_anperla"]            = {temp=100,   duration=7 },
   ["tech:mashed_anperla"]            = {temp=100,  duration=35 },
   ["nodes_nature:sea_lettuce"]       = {temp=100,   duration=3 },
   ["animals:carcass_invert_small"]   = {temp=100,   duration=1 },
   ["animals:carcass_invert_large"]   = {temp=100,   duration=3 },
   ["animals:carcass_bird_small"]     = {temp=100,   duration=6 },
   ["animals:carcass_fish_small"]     = {temp=100,   duration=6 },
   ["animals:carcass_fish_large"]     = {temp=100,  duration=18 },
}

-- tg=tag, ch=chance, sv=severity
-- base minimal food poisoning
local bm_fp = {tg="Food Poisoning",ch=0.001,sv=1}
HEALTH.harm_table = {
  -- player-craft
  ["tech:maraka_bread_cooked"]     = {bm_fp},
	["tech:maraka_bread_burned"]     = {bm_fp},
	["tech:peeled_anperla_cooked"]   = { {tg="Food Poisoning",ch=0.002,sv=1} },

  ["tech:mashed_anperla_cooked"]   = { {tg="Food Poisoning",ch=0.002,sv=1} },
	["tech:mashed_anperla_burned"]   = { {tg="Food Poisoning",ch=0.002,sv=1} },
  -- medicine/drugs
  ["tech:tiku"]                    = { {tg="Tiku High",ch=1,sv=1} },
  ["tech:tang"]                    = { {tg="Drunk",ch=0.75,sv=1} },
  ["tech:wooden_tang"]             = { {tg="Drunk",ch=0.75,sv=1} },
  -- cooked
  ["nodes_nature:sea_lettuce_cooked"] = { {tg="Food Poisoning",ch=0.002,sv=1} },
  -- fruits (not fruting)
  ["nodes_nature:obesa_fruit"]     = {bm_fp},
	["nodes_nature:muhle_fruit"]    = { {tg="Photosensitivity",ch=0.001,sv=1} },
	["nodes_nature:salia_fruit"]    = { {tg="Neurotoxicity",ch=0.001,sv=1} },
  ["nodes_nature:ziarnoplon_fruit"] = { {tg="Food Poisoning",ch=0.6,sv=1},
                                        {tg="Hepatotoxicity",ch=0.1,sv=1}},
  ["nodes_nature:srebroplon_fruit"] = { {tg="Food Poisoning",ch=0.6,sv=1},
                                        {tg="Hepatotoxicity",ch=0.1,sv=1}},
  ["nodes_nature:wrotycz_fruit"]   = { {tg="Food Poisoning",ch=0.1,sv=1},
                                        {tg="Hepatotoxicity",ch=0.005,sv=1} },
  ["nodes_nature:momo_fruit"]      = {bm_fp},
  ["nodes_nature:barszcz_fruit"]      = { {tg="Food Poisoning",ch=0.4,sv=1},
                                          {tg="Hepatotoxicity",ch=0.1,sv={1,2} }},
  ["nodes_nature:malina_fruit"]      = {bm_fp},
  ["nodes_nature:yellow_malina_fruit"]      = {bm_fp},
  ["nodes_nature:malinka_fruit"]      = {bm_fp},
  -- tree fruits
  ["nodes_nature:maraka_nut"]      = { bm_fp,
	                                     {tg="Hepatotoxicity",ch=0.005,sv={1,4} },
	                                     {tg="Photosensitivity",ch=0.3,sv=1} },
  ["nodes_nature:sasaran_cone"]    = { {tg="Food Poisoning",ch=0.08,sv=1} },
	["nodes_nature:tangkal_fruit"]   = { bm_fp,
	                                     { "Drunk",ch=0.005,sv=1} },
  ["nodes_nature:panasee_fruit"]   = {bm_fp},
	--To do: add mild stimulant for Amma (like coffee)?
	["nodes_nature:amma_nut"]        = {bm_fp},
	["nodes_nature:daoja_berry"]     = { bm_fp,
                                        {tg="Hepatotoxicity",ch=0.2,sv=1}},
  -- seeds
  ["nodes_nature:vansano_seed"]    = {bm_fp},
	["nodes_nature:tikusati_seed"]   = {bm_fp},
  -- mushrooms
  ["nodes_nature:nebiyi"]          = {bm_fp,
                                      {tg="Hepatotoxicity",ch=0.75,sv={1,4} }},
	["nodes_nature:marbhan"]         = {bm_fp,
                                      {tg="Neurotoxicity",ch=0.75,sv={1,4} } },
  ["nodes_nature:merki"]           = {bm_fp},
	["nodes_nature:zufani"]          = { {tg="Food Poisoning",ch=0.01,sv=1} },
  -- plants
  ["nodes_nature:tikusati"]        = {bm_fp},
  ["nodes_nature:gevaari"]         = {bm_fp,
                                      {tg="Hepatotoxicity",ch=1,sv=1} },
  ["nodes_nature:obesa"]           = { {tg="Food Poisoning",ch=0.5,sv=1},
                                        {tg="Hepatotoxicity",ch=0.001,sv=1}},
  ["nodes_nature:obesa_flowering"] = { {tg="Food Poisoning",ch=0.5,sv=1},
                                        {tg="Hepatotoxicity",ch=0.001,sv=1}},
  ["nodes_nature:obesa_fruitless"] = { {tg="Food Poisoning",ch=0.5,sv=1},
                                      {tg="Hepatotoxicity",ch=0.001,sv=1}},
  ["nodes_nature:ziarnoplon_flowering"] = { {tg="Food Poisoning",ch=0.6,sv=1},
                                            {tg="Hepatotoxicity",ch=0.1,sv=1}},
  ["nodes_nature:ziarnoplon_fruiting"]  = { {tg="Food Poisoning",ch=0.6,sv=1},
                                            {tg="Hepatotoxicity",ch=0.1,sv=1}},
  ["nodes_nature:ziarnoplon_fruitless"] = {bm_fp},
  ["nodes_nature:srebroplon_flowering"] = { {tg="Food Poisoning",ch=0.6,sv=1},
                                            {tg="Hepatotoxicity",ch=0.1,sv=1}},
  ["nodes_nature:srebroplon_fruiting"]  = { {tg="Food Poisoning",ch=0.6,sv=1},
                                            {tg="Hepatotoxicity",ch=0.1,sv=1}},
  ["nodes_nature:srebroplon_fruitless"] = {bm_fp},
  ["nodes_nature:hakimi_flowering"]   = {bm_fp},
  ["nodes_nature:galanta"]         = { {tg="Food Poisoning",ch=0.008,sv=1} },
  ["nodes_nature:galanta_seedling1"]  = {bm_fp},
  ["nodes_nature:galanta_seedling2"]  = { {tg="Food Poisoning",ch=0.002,sv=1} },
  ["nodes_nature:galanta_seedling3"]  = { {tg="Food Poisoning",ch=0.003,sv=1} },
  ["nodes_nature:galanta_seedling4"]  = { {tg="Food Poisoning",ch=0.004,sv=1} },
  ["nodes_nature:galanta_seedling5"]  = { {tg="Food Poisoning",ch=0.005,sv=1} },
  ["nodes_nature:damo_seedling1"]  = {bm_fp},
  ["nodes_nature:damo_seedling2"]  = {bm_fp},
  ["nodes_nature:damo_seedling3"]  = {bm_fp},
  ["nodes_nature:damo_seedling4"]  = {bm_fp},
  ["nodes_nature:damo_seedling5"]  = {bm_fp},

	["nodes_nature:fretin_seedling1"]  = {{tg="Photosensitivity",ch=0.001,sv=1}},
	["nodes_nature:fretin_seedling2"]  = {{tg="Photosensitivity",ch=0.002,sv=1}},
	["nodes_nature:fretin_seedling3"]  = {{tg="Photosensitivity",ch=0.003,sv=1}},
	["nodes_nature:fretin_seedling4"]  = {{tg="Photosensitivity",ch=0.004,sv=1}},
	["nodes_nature:fretin_seedling5"]  = {{tg="Photosensitivity",ch=0.005,sv=1}},

  ["nodes_nature:momo_fruiting"]   = {bm_fp},
  ["nodes_nature:momo_fruitless"]  = {bm_fp},
  ["nodes_nature:momo_flowering"]  = { {tg="Food Poisoning",ch=0.4,sv=1},
                                        {tg="Hepatotoxicity",ch=0.3,sv={1,2} }},
  ["nodes_nature:barszcz_fruiting"]   = { {tg="Food Poisoning",ch=0.4,sv=1},
                                          {tg="Hepatotoxicity",ch=0.1,sv={1,2} }},
  ["nodes_nature:barszcz_fruitless"]  = { {tg="Food Poisoning",ch=0.4,sv=1},
                                          {tg="Hepatotoxicity",ch=0.1,sv={1,2} }},
  ["nodes_nature:barszcz_flowering"]  = { {tg="Food Poisoning",ch=0.4,sv=1},
                                          {tg="Hepatotoxicity",ch=0.1,sv={1,2} }},
  ["nodes_nature:barszcz_root"]       = { {tg="Food Poisoning",ch=0.01,sv=1},
                                          {tg="Hepatotoxicity",ch=0.01,sv={1,2} }},
  ["nodes_nature:rzepicha_root"]     = {bm_fp},
  ["nodes_nature:rzepicha_root_winter"]     = {bm_fp},
  -- sea plants
  ["nodes_nature:sea_lettuce"]     = { {tg="Food Poisoning",ch=0.050,sv=1},
                                      {tg="Intestinal Parasites",ch=0.010} },
  -- meats
  ["animals:carcass_invert_small"] = { {tg="Food Poisoning",ch=0.1,sv=1},
	                                     {tg="Intestinal Parasites",ch=0.01,sv=1} },
	["animals:carcass_invert_small_cooked"] = { {tg="Food Poisoning",ch=0.002,sv=1} },
	["animals:carcass_invert_small_burned"] = { bm_fp },
	["animals:carcass_invert_large"] = { {tg="Food Poisoning",ch=0.2,sv=1},
	                                     {tg="Intestinal Parasites",ch=0.02,sv=1} },
	["animals:carcass_invert_large_cooked"] = { {tg="Food Poisoning",ch=0.002,sv=1} },
	["animals:carcass_invert_large_burned"] = { bm_fp },
	["animals:carcass_bird_small"]   = { {tg="Food Poisoning",ch=0.05,sv=1},
	                                     {tg="Intestinal Parasites",ch=0.02,sv=1} },
	["animals:carcass_bird_small_cooked"] = { {tg="Food Poisoning", 0.002,sv=1} },
	["animals:carcass_bird_small_burned"] = { bm_fp },
	["animals:carcass_fish_small"]   = { {tg="Food Poisoning",ch=0.05,sv=1},
	                                     {tg="Intestinal Parasites",ch=0.02,sv=1} },
	["animals:carcass_fish_small_cooked"] = { {tg="Food Poisoning",ch=0.002,sv=1} },
	["animals:carcass_fish_small_burned"] = { bm_fp },
	["animals:carcass_fish_large"]   = { {tg="Food Poisoning",ch=0.1,sv=1},
	                                     {tg="Intestinal Parasites",ch=0.04,sv=1} },
	["animals:carcass_fish_large_cooked"] = { {tg="Food Poisoning",ch=0.004,sv=1} },
	["animals:carcass_fish_large_burned"] = { {tg="Food Poisoning",ch=0.002,sv=1} },
	--eggs
	["animals:darkasthaan_eggs"]     = { {tg="Food Poisoning",ch=0.1,sv={1,4} },
	                                     {tg="Intestinal Parasites",ch=0.01,sv=1} },
	["animals:gundu_eggs"]           = { {tg="Food Poisoning",ch=0.05,sv={1,4} },
	                                     {tg="Intestinal Parasites",ch=0.1,sv=1} },
	["animals:impethu_eggs"]         = { {tg="Food Poisoning",ch=0.1,sv={1,4} },
	                                     {tg="Intestinal Parasites",ch=0.1,sv=1} },
	["animals:kubwakubwa_eggs"]      = { {tg="Food Poisoning",ch=0.1,sv={1,4} },
	                                     {tg="Intestinal Parasites",ch=0.01,sv=1} },
	["animals:pegasun_eggs"]         = { {tg="Food Poisoning",ch=0.02,sv={1,2} },
	                                     {tg="Intestinal Parasites",ch=0.005,sv=1} },
	["animals:sarkamos_eggs"]       = { {tg="Food Poisoning",ch=0.3,sv={1,4} },
	                                     {tg="Intestinal Parasites",ch=0.05,sv=1} },
	["animals:sneachan_eggs"]       = { {tg="Food Poisoning",ch=0.5,sv={1,4} },
	                                     {tg="Intestinal Parasites",ch=0.5,sv=1} },
}

HEALTH.cure_table = {
  -- plants + mushrooms
  -- hakimi is antibacterial, antifungal - only cure mild
  ["nodes_nature:hakimi_flowering"] = {ch=0.75,sv=1,{tgs="Food Poisoning","Fungal Infection", "Dust Fever"} },
  -- merki is anti-parasitic
  ["nodes_nature:merki"] = { {tg="Intestinal Parasites",ch=0.15,sv=1} },
  -- medicine/drugs
  --cure/reduce food poisoning and infections
  ["tech:herbal_medicine"] = {function() -- custom supported function argument
                              local cure = {ch=1,sv=1,tgs={"Food Poisoning","Fungal Infection","Dust Fever"}}
                              local c = math.random()
                              if c <= 0.25 then -- cure severe
                                cure.sv = 3
                              elseif c <= 0.5 then -- cure moderate
                                cure.sv = 2
                              end
                              if c <= 0.75 then
                                -- only cure if chance is less than 75%, sv is 1 base (mild cure)
                                return cure
                              end
                            end,
                            {tg="Intestinal Parasites",ch=0.33,sv=1}}
}
