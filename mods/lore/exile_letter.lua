
----------------------------------------------------------
--EXILE LETTER
--[[
sentence of exile.
Unique, randomly generated, for each "life".
 i.e. Respawn means starting as someone new

 Sets the scene for the game.
 Explains why you are there, and where "there" is.


]]


local random = math.random
lore = lore
local S = lore.S

----------------------------------------------------------
local judger = {
  --monarchs, etc.
  "King",
  "Queen",
  "Emperor",
  "Empress",
  "Exalted Ruler",
  "Majestic Leader",
  "High King",
  "High Queen",
  "Nobles",
  "Lords",
  "Duke",
  "Duchess",
  "Lord",
  "Most Highly Exalted Supreme Ruler",
  "Great Leader",
  "Golden King",
  "Jade Queen",
  "Prince",
  "Princess",
  "Regent",
  "Dictator",
  --officials
  "High Judge",
  "Tribunal",
  "Council",
  "Courts",
  "Presidium",
  "Law Givers",
  "King's Justice",
  "Sheriff",
  "Exarch",
  "Prefect",
  "Seneschal",
  --cults
  "Brotherhood",
  "Sisterhood",
  "High Priest",
  "High Priestess",
  "Great Prophet",
  "Anointed One",
  "God King",
  "Philosopher King",
  "Seers",
  "Sanctum",
  "Order",
  "Monks",
  "Priests",
  "Priestesses",
  "Enlightened Ones",
  "Great Sage",
  "Shaman",
  --tribal
  "Elders",
  "Wise Ones",
  "Clan Council",
  "Tribal Chiefs",
  "Great Chieftain",
  "United Clans",
  "Wise Man",
  "Wise Woman",
  --republic
  "Citizenry",
  "People",
  "Senate",
  "Consul",
  "Senators",
  "Assembly",
  "Chief Minister",
  --Geographic/polity
  "City State",
  "Empire",
  "Kingdom",
  "Principality",
  "Duchy",
  "Republic",
  "League",
  "Confederation",
  "Federation",
  "Alliance",
  "Coalition",
  "Nation",
  "Clan",
  "Chiefdom",
  "Tribe",
  "Monastic Order",
  "Merchant Republic",
  "Theocracy",
  --Military
  "Generals",
  "Champion",
  "Mighty Warriors",
  "Admirals",
  "Legion",
  "Commander",
  "Commandant",
  "Warlord",
  --rogues
  "Pirates",
  "Bandits",
  "Company",
  "Horde",
  "Liberators",
  "Destroyers",
  --freaky
  "All Seeing Eye",
  "Old Children",
  "Spectre",
  "Dragon King",
  "Seven Hands",
  "Imperial Phlogistonist",
  "Sacred Snake-god",
  "Eternal Pyramid",
  "Towering Tree",
  "Viridian Magister",
  "Thousand-tongued All-speaker"
}
-- exile-worthy crime
local crime1 = {
  "treason",
  "betrayal",
  "murder",
  "heresy",
  "blasphemy",
  "betrayal",
  "regicide",
  "conspiracy",
  "kidnapping",
  "corruption",
  "abduction",
  "subversion",
  "mutiny",
  "rebellion",
  "usurpation",
  "espionage",
  "sabotage",
  "treachery",
  "sedition"
}
-- flavour-text crime
local crime2 = {
  "leading the youth astray",
  "smuggling contraband",
  "vagabondage",
  "banditry",
  "piracy absent a letter of marque",
  "drunkenness",
  "sinful living",
  "rabble rousing",
  "inciting violence",
  "unspeakable acts",
  "that of which we shall not speak",
  "endangering the survival of our people",
  "causing the great tragedy that befell us",
  "refusing to partake in the sacred rituals",
  "shameless acts",
  "willful sloth",
  "preaching foreign gods",
  "gross vanity",
  "wickedness",
  "assassination of one who was high-born",
  "sharing secrets with foreign powers",
  "black magic",
  "witchcraft afflicting the fertility of our crops",
  "placing curses upon the innocent",
  "shameful conduct",
  "cowardice in the face of glory",
  "tax evasion",
  "abusing their station for personal gain",
  "desecration of holy relics",
  "subverting the course of justice",
  "robbery",
  "attempted murder",
  "grave robbing",
  "cruelty to animals",
  "eating forbidden foods",
  "embezzlement",
  "questioning the gloriousness of our ways",
  "bearing false witness",
  "deception of those who must be obeyed",
  "fraud",
  "fakery",
  "consorting with disreputables",
  "trespassing upon the tall tower",
  "poaching on royal lands",
  "impersonation of an official",
  "insulting our great leaders",
  "disobedience toward rightful authority",
  "dealing in harmful potions",
  "pickpocketing pious pilgrims",
  "possession of stolen goods",
  "rioting",
  "racketeering",
  "arson",
  "soliciting assassins to commit murder",
  "stealing livestock",
  "usury",
  "aspirations to tyranny",
  "improper ambition",
  "failing to venerate the gods",
  "vandalism",
  "abidingly uncouth comportment",
  "adopting barbarian customs",
  "speaking a forbidden tongue",
  "harassment",
  "forgery",
  "bribery",
  "forsaking our ancestors",
  "mocking all that is good",
  "stubborn foolishness",
  "persistent idiocy",
  "failure to exercise one's duty",
  "disregard of honor",
  "breaking the faith",
  "touching the forbidden",
  "seeking banned knowledge",
  "slander",
  "rejecting common sense",
  "failing to appear for military service",
  "hoarding food during famine",
  "befouling the good reputation of our people",
  "sowing discord among the populace",
  "sleeping with unclean creatures",
  "violating the chastity of the priesthood",
  "marrying outside their caste",
  "cheating at dice",
  "gardening without a permit",
  "stealing priceless art",
  "aiding an adulterous princess",
  "leading an unauthorised military campaign",
  "claiming that the world is round",
  "claiming that the world is not round",
  "promoting belief in gravity"
}

-- woe upon ye
local woe = {}
local genderSU = {male = S("He"),  female = S("She") } -- subjective + uppercase
local genderSL = {male = S("he"),  female = S("she") } -- subjective + lowercase
local genderOU = {male = S("Him"), female = S("Her") } -- objective  + uppercase
local genderOL = {male = S("him"), female = S("her") } -- objective  + lowercase
local genderPU = {male = S("His"), female = S("Her") } -- possessive + uppercase
local genderPL = {male = S("his"), female = S("her") } -- possessive + lowercase
local genderRU = {male = S("Himself"),
		  female = S("Herself")} -- reflexive  + uppercase
local genderRL = {male = S("himself"),
		  female = S("herself")} -- reflexive  + lowercase
local populate_woe = function(player)
	local gend = player_api.get_gender(player)
	return {
	  S("May @1 name be forgotten.", genderPL[gend]),
	  S("@1 is proscribed.", genderSU[gend]),
	  S("Never suffer @1 to return.", genderOL[gend]),
	  S("May the gods have mercy upon @1.", genderOL[gend]),
	  S("Let none come to @1 aid.", genderPL[gend]),
	  S("May @1 weeping never cease.", genderPL[gend]),
	  S("@1 life is forfeit.", genderPU[gend]),
	  S("It shall be as if @1 were never born.", genderSL[gend]),
	  S("May @1 end be swift.", genderPL[gend]),
	  S("May fortune forgive @1.", genderOL[gend]),
	  S("@1 shall live so long as @2 deserves.", genderSU[gend], genderSL[gend]),
	  S("Let the beasts do with @1 as they wish.", genderOL[gend]),
	  S("This is justice."),
	  S("Let none dispute it."),
	  S("May @1 wander fruitlessly.", genderSL[gend]),
	  S("May @1 bones bleach in the sun.", genderPL[gend]),
	  S("May the worms feast on @1 flesh.", genderPL[gend]),
	  S("May @1 suffering appease the gods.", genderPL[gend]),
	  S("Let @1 struggling be without end.", genderPL[gend]),
	  S("Let fate decide @1 destiny.", genderPL[gend]),
	  S("May the land have pity and bury @1 disgraceful remains.", genderPL[gend]),
	  S("Thus we declare."),
	  S("For we are merciful."),
	  S("Let this be our kindness to @1.", genderOL[gend]),
	  S("Begone, evildoer."),
	  S("Thus do we cleanse ourselves."),
	  S("We wash our hands of @1.", genderOL[gend]), -- Perhaps a reference to Pontius Pilate
	  S("Fortune shall be @1 final judge.", genderPL[gend]),
	  S("@1 is disowned.", genderSU[gend]),
	  S("We never knew @1.", genderOL[gend]),
	  S("@1 is cut off.", genderSU[gend]),
	  S("Let @1 live with the beasts.", genderOL[gend]),
	  S("Let the barbarians and wild folk have @1.", genderOL[gend]),
	  S("@1 is not fit for civilised lands.", genderSU[gend]),
	  S("Thus we ensure our security."), -- Perhaps a reference to Sheev Palpatine
	  S("Only the righteous belong among us."),
	  S("May @1 toil in vain.", genderSL[gend]),
	  S("So it is written. So it is done."), -- Now a reference to Cecil B. DeMille
	  S("Even the dogs despise @1.", genderOL[gend]),
	  S("We break no bread with traitors."),
	  S("Let this be @1 journey to cleanse @2.", genderPL[gend], genderRL[gend])
	}
end
-- Various corruptions of "Ozymandias"
local exile = {
  "Ochymadion",
  "Aseymedius",
  "Eshenadios",
  "Uzymandeos",
  "Isemendion",
  "Zymenios",
  "Hocheemundis",
  "Otemanediate",
  "Oisemondas",
  "Wazymdis",
  "Wazhmindas",
  "Okaemanadia",
  "Caemandior",
  "Oshaemediash",
  "Otzakantas",
  "Archanatus"
}
-- What happened here? Lost to memory.
local mythic_terror = {
  "Great Calamity",
  "Collapse",
  "Unending Curse",
  "Ancient Curse",
  "Manifested Curses",
  "Curse",
  "Catastrophe",
  "Great Dying",
  "Mythic Terror",
  "Cold Night",
  "Night",
  "Darkness",
  "Shadows",
  "Woeful Shades",
  "Scourge",
  "Plague",
  "Eternal Plague",
  "Sleeping Evil",
  "Fiery Breath",
  "Great Burning",
  "Great Bleeding",
  "Baneful Blights",
  "Blight",
  "Ceaseless Withering",
  "Ancient Exodus",
  "Fearful Horror",
  "Evil Spirits",
  "Ghosts",
  "Haunting",
  "Wrathful Spirits",
  "Grim Fate",
  "Rumbling Earth",
  "Scorched Wastes",
  "Burning Rock",
  "Smoldering Soil",
  "Great Folly",
  "Old Tales",
  "Evil Wind",
  "Bitter Waters",
  "Everlasting Tempest",
  "Howling Dust",
  "Hateful Sky",
  "Great Confusion",
  "Twisted Existence",
  "Twisted",
  "Warped",
  "Lost"
}

local function get_string(meta, stringname)
   --minetest's get_string returns non-nil for an empty string
   local get = meta:get_string(stringname)
   if get == "" then
      return nil
   else
      return get
   end
end

local generate_text = function(player, freshspawn)
  local letter_text

  local meta = player:get_meta()
  local your_name   = meta:get_string("char_name")
  local gend        = player_api.get_gender(player)
  woe               = populate_woe(player)
  local judge       = judger[random(#judger)]
  local origin_name = lore.generate_name(4)
  local polity_name = lore.generate_name(5)
  local cr1         = crime1[random(#crime1)]
  local cr2         = crime2[random(#crime2)]
  local your_woe    = woe[random(#woe)]
  local exile_land  = exile[random(#exile)]
  local terror      = mythic_terror[random(#mythic_terror)]
  if freshspawn then
     meta:set_string("ex_judger", judge)
     meta:set_string("ex_origin", origin_name)
     meta:set_string("ex_polity", polity_name)
     meta:set_string("ex_crime1", cr1)
     meta:set_string("ex_crime2", cr2)
     meta:set_string("ex_woe", your_woe)
     meta:set_string("ex_land", exile_land)
     meta:set_string("ex_terror", terror)
  else
     judge       = get_string(meta, "ex_judger") or judge
     origin_name = get_string(meta, "ex_origin") or origin_name
     polity_name = get_string(meta, "ex_polity") or polity_name
     cr1         = get_string(meta, "ex_crime1") or cr1
     cr2         = get_string(meta, "ex_crime2") or cr2
     your_woe    = get_string(meta, "ex_woe") or your_woe
     exile_land  = get_string(meta, "ex_land") or exile_land
     terror      = get_string(meta, "ex_terror") or terror
  end

  --
  letter_text = "<center><b>"..
     S("By decree of the @1 of @2: @n@n"..
       " @3 of @4 @n@n"..
       " is hereby sentenced to exile for the crimes of @n@n"..
       " @5 @n@n and @n@n @6 @n@n@n"..
       " @7 is hereby banished to the land of @8 @n@n"..
       " The land of the @9 @n@n",
       S(judge), polity_name, your_name, origin_name, S(cr1), S(cr2), genderSU[gend],
       S(exile_land), S(terror))..
     "<i>"..your_woe

  return letter_text
end

--------------------------------------------
local function get_formspec(meta, letter_text)

   local formspec = {
    "size[9,11]",
    "hypertext[0.75,1;8,10.6;;"..minetest.formspec_escape(letter_text) .."]",
    "button_exit[8.2,10.6;0.8,0.5;exit_form;X]",
    "background[0,0;18,11;lore_exile_letter_bg.png;true]"}
   local pname = meta:get_string("creator")
   if pname then
      formspec[1] = formspec[1].."hypertext[0.5,10.5;8,1;;"..
	 "<style color=#000><i>"..pname.."]"
   end
   return table.concat(formspec, "")
end

local function setup_letter(player, imeta)
   if not imeta then
      minetest.log("error", "Tried to set up a letter with invalid item metatable")
      return nil
   end
   local letter_text = imeta:get_string("lore:letter_text")
   if letter_text == "" then
      letter_text = generate_text(player)
      imeta:set_string("lore:letter_text", letter_text)
   end
   return letter_text
end

-----------------------------------------------
local after_place = function(pos, placer, itemstack, pointed_thing)
  local meta = minetest.get_meta(pos)
  local stack_meta = itemstack:get_meta()
  local letter_text = setup_letter(placer, stack_meta)
  local form = get_formspec(meta, letter_text )
  meta:set_string("formspec", form)
  meta:set_string("lore:letter_text", letter_text)
end

local on_secondary_use = function(itemstack, user, pointed_thing)
   if pointed_thing.type == "object" then return end -- canoe/airboat
   local meta = itemstack:get_meta()
   local letter_text = setup_letter(user, meta)
   local form = get_formspec(meta, letter_text)
   local pname = user:get_player_name()
   minetest.show_formspec(pname, "lore:exile_letter", form)
end

---------------------------------------------
--Placeable Node
minetest.register_node("lore:exile_letter", {
	description = S("Sentence of Exile"),
	tiles = {"lore_exile_letter.png"},
  --inventory_image = {"lore_exile_letter_inv.png"},
	stack_max = 1,
  paramtype = "light",
  paramtype2 = "wallmounted",
  sunlight_propagates = true,
  walkable = false,
  drawtype = "nodebox",
  node_box = {
     type = "fixed",
     fixed = {-0.35, -0.5, -0.4, 0.35, -0.45, 0.4},
  },
  groups = {dig_immediate = 3, temp_pass = 1, flammable = 1},
  sounds = nodes_nature.node_sound_leaves_defaults(),
  after_place_node = after_place,
  on_secondary_use = on_secondary_use,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
     local imeta = drops[1]:get_meta()
     imeta:from_table({
	   fields = { creator = oldmeta.creator,
		      ["lore:letter_text"] = oldmeta["lore:letter_text"] } })
  end,
})


--------------------------------------
minetest.register_on_newplayer(function(player)
  local inv = player:get_inventory()
  local letter = ItemStack("lore:exile_letter")
  local stack_meta = letter:get_meta()
  stack_meta:set_string("creator", player:get_player_name())
  stack_meta:set_string("lore:letter_text", generate_text(player, "new"))
  inv:add_item("main", letter)
end)

minetest.register_on_respawnplayer(function(player)
  local inv = player:get_inventory()
  local letter = ItemStack("lore:exile_letter")
  local stack_meta = letter:get_meta()
  stack_meta:set_string("creator", player:get_player_name())
  stack_meta:set_string("lore:letter_text", generate_text(player, "new"))
  inv:add_item("main", letter)
end)
