
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
local S = lore.S
local NS = function(s) return s end

----------------------------------------------------------
local judger = {
    --monarchs, etc.
    NS("King"),
    NS("Queen"),
    NS("Emperor"),
    NS("Empress"),
    NS("Exalted Ruler"),
    NS("Majestic Leader"),
    NS("High King"),
    NS("High Queen"),
    NS("Nobles"),
    NS("Lords"),
    NS("Duke"),
    NS("Duchess"),
    NS("Lord"),
    NS("Most Highly Exalted Supreme Ruler"),
    NS("Great Leader"),
    NS("Golden King"),
    NS("Jade Queen"),
    NS("Prince"),
    NS("Princess"),
    NS("Regent"),
    NS("Dictator"),
    --officials
    NS("High Judge"),
    NS("Tribunal"),
    NS("Council"),
    NS("Courts"),
    NS("Presidium"),
    NS("Law Givers"),
    NS("King's Justice"),
    NS("Sheriff"),
    NS("Exarch"),
    NS("Prefect"),
    NS("Seneschal"),
    --cults
    NS("Brotherhood"),
    NS("Sisterhood"),
    NS("High Priest"),
    NS("High Priestess"),
    NS("Great Prophet"),
    NS("Anointed One"),
    NS("God King"),
    NS("Philosopher King"),
    NS("Seers"),
    NS("Sanctum"),
    NS("Order"),
    NS("Monks"),
    NS("Priests"),
    NS("Priestesses"),
    NS("Enlightened Ones"),
    NS("Great Sage"),
    NS("Shaman"),
    --tribal
    NS("Elders"),
    NS("Wise Ones"),
    NS("Clan Council"),
    NS("Tribal Chiefs"),
    NS("Great Chieftain"),
    NS("United Clans"),
    NS("Wise Man"),
    NS("Wise Woman"),
    --republic
    NS("Citizenry"),
    NS("People"),
    NS("Senate"),
    NS("Consul"),
    NS("Senators"),
    NS("Assembly"),
    NS("Chief Minister"),
    --Geographic/polity
    NS("City State"),
    NS("Empire"),
    NS("Kingdom"),
    NS("Principality"),
    NS("Duchy"),
    NS("Republic"),
    NS("League"),
    NS("Confederation"),
    NS("Federation"),
    NS("Alliance"),
    NS("Coalition"),
    NS("Nation"),
    NS("Clan"),
    NS("Chiefdom"),
    NS("Tribe"),
    NS("Monastic Order"),
    NS("Merchant Republic"),
    NS("Theocracy"),
    --Military
    NS("Generals"),
    NS("Champion"),
    NS("Mighty Warriors"),
    NS("Admirals"),
    NS("Legion"),
    NS("Commander"),
    NS("Commandant"),
    NS("Warlord"),
    --rogues
    NS("Pirates"),
    NS("Bandits"),
    NS("Company"),
    NS("Horde"),
    NS("Liberators"),
    NS("Destroyers"),
    --freaky
    NS("All Seeing Eye"),
    NS("Old Children"),
    NS("Spectre"),
    NS("Dragon King"),
    NS("Seven Hands"),
    NS("Imperial Phlogistonist"),
    NS("Sacred Snake-god"),
    NS("Eternal Pyramid"),
    NS("Towering Tree"),
    NS("Viridian Magister"),
    NS("Thousand-tongued All-speaker")
}
-- exile-worthy crime
local crime1 = {
    NS("treason"),
    NS("betrayal"),
    NS("murder"),
    NS("heresy"),
    NS("blasphemy"),
    NS("betrayal"),
    NS("regicide"),
    NS("conspiracy"),
    NS("kidnapping"),
    NS("corruption"),
    NS("abduction"),
    NS("subversion"),
    NS("mutiny"),
    NS("rebellion"),
    NS("usurpation"),
    NS("espionage"),
    NS("sabotage"),
    NS("treachery"),
    NS("sedition")
}
-- flavour-text crime
local crime2 = {
    NS("leading the youth astray"),
    NS("smuggling contraband"),
    NS("vagabondage"),
    NS("banditry"),
    NS("piracy absent a letter of marque"),
    NS("drunkenness"),
    NS("sinful living"),
    NS("rabble rousing"),
    NS("inciting violence"),
    NS("unspeakable acts"),
    NS("that of which we shall not speak"),
    NS("endangering the survival of our people"),
    NS("causing the great tragedy that befell us"),
    NS("refusing to partake in the sacred rituals"),
    NS("shameless acts"),
    NS("willful sloth"),
    NS("preaching foreign gods"),
    NS("gross vanity"),
    NS("wickedness"),
    NS("assassination of one who was high-born"),
    NS("sharing secrets with foreign powers"),
    NS("black magic"),
    NS("witchcraft afflicting the fertility of our crops"),
    NS("placing curses upon the innocent"),
    NS("shameful conduct"),
    NS("cowardice in the face of glory"),
    NS("tax evasion"),
    NS("abusing their station for personal gain"),
    NS("desecration of holy relics"),
    NS("subverting the course of justice"),
    NS("robbery"),
    NS("attempted murder"),
    NS("grave robbing"),
    NS("cruelty to animals"),
    NS("eating forbidden foods"),
    NS("embezzlement"),
    NS("questioning the gloriousness of our ways"),
    NS("bearing false witness"),
    NS("deception of those who must be obeyed"),
    NS("fraud"),
    NS("fakery"),
    NS("consorting with disreputables"),
    NS("trespassing upon the tall tower"),
    NS("poaching on royal lands"),
    NS("impersonation of an official"),
    NS("insulting our great leaders"),
    NS("disobedience toward rightful authority"),
    NS("dealing in harmful potions"),
    NS("pickpocketing pious pilgrims"),
    NS("possession of stolen goods"),
    NS("rioting"),
    NS("racketeering"),
    NS("arson"),
    NS("soliciting assassins to commit murder"),
    NS("stealing livestock"),
    NS("usury"),
    NS("aspirations to tyranny"),
    NS("improper ambition"),
    NS("failing to venerate the gods"),
    NS("vandalism"),
    NS("abidingly uncouth comportment"),
    NS("adopting barbarian customs"),
    NS("speaking a forbidden tongue"),
    NS("harassment"),
    NS("forgery"),
    NS("bribery"),
    NS("forsaking our ancestors"),
    NS("mocking all that is good"),
    NS("stubborn foolishness"),
    NS("persistent idiocy"),
    NS("failure to exercise one's duty"),
    NS("disregard of honor"),
    NS("breaking the faith"),
    NS("touching the forbidden"),
    NS("seeking banned knowledge"),
    NS("slander"),
    NS("rejecting common sense"),
    NS("failing to appear for military service"),
    NS("hoarding food during famine"),
    NS("befouling the good reputation of our people"),
    NS("sowing discord among the populace"),
    NS("sleeping with unclean creatures"),
    NS("violating the chastity of the priesthood"),
    NS("marrying outside their caste"),
    NS("cheating at dice"),
    NS("gardening without a permit"),
    NS("stealing priceless art"),
    NS("aiding an adulterous princess"),
    NS("leading an unauthorised military campaign"),
    NS("claiming that the world is round"),
    NS("claiming that the world is not round"),
    NS("promoting belief in gravity")
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
        S("May the land have pity and bury @1 disgraceful remains.",
          genderPL[gend]),
        S("Thus we declare."),
        S("For we are merciful."),
        S("Let this be our kindness to @1.", genderOL[gend]),
        S("Begone, evildoer."),
        S("Thus do we cleanse ourselves."),
        S("We wash our hands of @1.", genderOL[gend]),
        -- Perhaps a reference to Pontius Pilate
        S("Fortune shall be @1 final judge.", genderPL[gend]),
        S("@1 is disowned.", genderSU[gend]),
        S("We never knew @1.", genderOL[gend]),
        S("@1 is cut off.", genderSU[gend]),
        S("Let @1 live with the beasts.", genderOL[gend]),
        S("Let the barbarians and wild folk have @1.", genderOL[gend]),
        S("@1 is not fit for civilised lands.", genderSU[gend]),
        S("Thus we ensure our security."),
        -- Perhaps a reference to Sheev Palpatine
        S("Only the righteous belong among us."),
        S("May @1 toil in vain.", genderSL[gend]),
        S("So it is written. So it is done."),
        -- Now a reference to Cecil B. DeMille
        S("Even the dogs despise @1.", genderOL[gend]),
        S("We break no bread with traitors."),
        S("Let this be @1 journey to cleanse @2.", genderPL[gend], genderRL[gend])
    }
end
-- Various corruptions of "Ozymandias"
local exile = {
    NS("Ochymadion"),
    NS("Aseymedius"),
    NS("Eshenadios"),
    NS("Uzymandeos"),
    NS("Isemendion"),
    NS("Zymenios"),
    NS("Hocheemundis"),
    NS("Otemanediate"),
    NS("Oisemondas"),
    NS("Wazymdis"),
    NS("Wazhmindas"),
    NS("Okaemanadia"),
    NS("Caemandior"),
    NS("Oshaemediash"),
    NS("Otzakantas"),
    NS("Archanatus")
}
-- What happened here? Lost to memory.
local mythic_terror = {
    NS("Great Calamity"),
    NS("Collapse"),
    NS("Unending Curse"),
    NS("Ancient Curse"),
    NS("Manifested Curses"),
    NS("Curse"),
    NS("Catastrophe"),
    NS("Great Dying"),
    NS("Mythic Terror"),
    NS("Cold Night"),
    NS("Night"),
    NS("Darkness"),
    NS("Shadows"),
    NS("Woeful Shades"),
    NS("Scourge"),
    NS("Plague"),
    NS("Eternal Plague"),
    NS("Sleeping Evil"),
    NS("Fiery Breath"),
    NS("Great Burning"),
    NS("Great Bleeding"),
    NS("Baneful Blights"),
    NS("Blight"),
    NS("Ceaseless Withering"),
    NS("Ancient Exodus"),
    NS("Fearful Horror"),
    NS("Evil Spirits"),
    NS("Ghosts"),
    NS("Haunting"),
    NS("Wrathful Spirits"),
    NS("Grim Fate"),
    NS("Rumbling Earth"),
    NS("Scorched Wastes"),
    NS("Burning Rock"),
    NS("Smoldering Soil"),
    NS("Great Folly"),
    NS("Old Tales"),
    NS("Evil Wind"),
    NS("Bitter Waters"),
    NS("Everlasting Tempest"),
    NS("Howling Dust"),
    NS("Hateful Sky"),
    NS("Great Confusion"),
    NS("Twisted Existence"),
    NS("Twisted"),
    NS("Warped"),
    NS("Lost")
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
          S(judge), polity_name, your_name, origin_name,
          S(cr1), S(cr2), genderSU[gend],

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
        minetest.log("error",
                     "Tried to set up a letter with invalid item metatable")
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
local after_place = function(pos, placer, itemstack, _pt, nmeta, imeta)
    nmeta = nmeta or core.get_meta(pos)
    imeta = imeta or itemstack:get_meta()
    local letter_text = setup_letter(placer, imeta)
    local form = get_formspec(nmeta, letter_text )
    nmeta:set_string("formspec", form)
    nmeta:set_string("lore:letter_text", letter_text)
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
minetest.register_node(
    "lore:exile_letter", {
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
        preserve_metadata = function(_pos, _oldnode, oldmeta, drops, imeta)
            imeta = imeta or drops[1] and drops[1]:get_meta()
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
        local meta = player:get_meta()
        if meta:get("playtime_suspended") then return end
        local inv = player:get_inventory()
        local letter = ItemStack("lore:exile_letter")
        local stack_meta = letter:get_meta()
        stack_meta:set_string("creator", player:get_player_name())
        stack_meta:set_string("lore:letter_text", generate_text(player, "new"))
        inv:add_item("main", letter)
end)
