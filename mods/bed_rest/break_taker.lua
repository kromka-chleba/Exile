local S = minetest.get_translator("bed_rest")
local NS = function(s) return s end

----------------------------------------------------
--Break taker
--

local quote_list = {
    -- Roman/Latin
    [NS("Seneca")] = {
        NS("Sometimes even to live is an act of courage.")
    },
    [NS("Cicero")] = {
        NS("It is not by muscle, speed, or physical dexterity that great things are achieved,\nbut by reflection, force of character, and judgment.")
    },
    [NS("Ovid")] = {
        NS("Dripping water hollows out stone,\nnot through force but through persistence.")
    },
    [NS("Marcus Aurelius")] = {
        NS("Life is a struggle and wandering in a foreign country.")
    },
    -- Greek
    [NS("Hippocrates")] = {
        NS("Let food be thy medicine and medicine be thy food.")
    },
    -- Chinese Mainland + Taiwan + Tibet
    [NS("Sun Tzu")] = {
        NS("If quick, I survive. If not quick, I am lost.")
    },
    [NS("Lao Tzu")] = {
        NS("Fill your bowl to the brim and it will spill.\nKeep sharpening your knife and it will blunt.")
    },
    [NS("Confucius")] = { -- Kong Fuzi
        NS("Learning without thought is labour lost;\nthought without learning is perilous.")
    },
    [NS("Chongyang")] = {
        NS("Reed-thatched huts and grass-thatched shelters are essential for protecting the body.\nTo sleep in the open air or in the open fields offends the sun and moon."),
        NS("On the other hand,\nliving beneath carved beams and high eaves is also not the action of a superior adept.\nGreat palaces and elevated halls,\n— how can these be part of the living plan for followers of the Dao?"),
        NS("Medicinal herbs are the flourishing emanations of mountains and waterways,\nthe essential florescence of plants and trees."),
        NS("Followers of the Dao join together as companions\nbecause they can assist each other in sickness and disease.\nIf you die, I’ll bury you; if I die, you’ll bury me.")
    },
    [NS("The Dalai Lama")] = {
        NS("If you think you are too small to make a difference,\ntry sleeping with a mosquito.")
    },
    -- Japanese
    [NS("Masanobu Fukuoka")] = {
        NS("The ultimate goal of farming is not the growing of crops,\nbut the cultivation and perfection of human beings.")
    },
    [NS("Kazuaki Tanahashi")] = {
        NS("Artist's need the world.")
    },
    [NS("Kobayashi Issa")] = {
        NS("O snail\nClimb Mount Fuji\nBut slowly, slowly!")
    },
    -- Indian Subcontinent (India)
    [NS("Mahatma Gandhi")] = {
        NS("Each night, when I go to sleep, I die.\nAnd the next morning, when I wake up, I am reborn.")
    },
    -- Iranian
    [NS("Saadi")] = {
        NS("Whatever is produced in haste goes hastily to waste.")
    },
    -- Filipino
    [NS("Nick Joaquín")] = {
        NS("The point is not how we use a tool, but how it uses us.")
    },
    -- Australian
    [NS("John Plant")] = {
        NS("My approach is to look for what I’m interested in using\nand if it’s there I use it.")
    },
    -- American
    [NS("Joss Whedon")] = {
        NS("Humor keeps us alive. Humor and food.\nDon't forget food. You can go a week without laughing."),
    },
    [NS("Carl Sagan")] = {
        NS("Extinction is the rule.\nSurvival is the exception."),
        NS("Somewhere, something incredible is waiting to be known."),
        NS("If you wish to make an apple pie from scratch, you must first invent the universe."),
    },
    [NS("Edwin Louis Cole")] = {
        NS("You don't drown by falling in the water;\nyou drown by staying there.")
    },
    [NS("Ernest Hemmingway")] = {
        NS("Never confuse movement with action.")
    },
    [NS("Kurt Vonnegut")] = {
        NS("A step backward, after making a wrong turn, is a step in the right direction.")
    },
    [NS("Jane Addams")] = {
        NS("Perhaps nothing is so fraught with significance as the human hand,\nthis oldest tool with which man has dug his way from savagery,\nand with which he is constantly groping forward.")
    },
    [NS("Barry Gehm")] = {
        NS("Any technology distinguishable from magic is insufficiently advanced.") -- Isn't this a quote stolen from Arthur C Clarke? lol
    },
    [NS("Bob Ross")] = {
        NS("Lets build a happy little cloud.\nLets build some happy little trees.")
    },
    [NS("John Muir")] = { -- Scottish born American
        NS("The mountains are calling and I must go.")
    },
    [NS("Ralph Waldo Emerson")] = {
        NS("Adopt the pace of nature: her secret is patience.")
    },
    [NS("Daniel Boone")] = {
        NS("I've never been lost, but I was mighty turned around for three days once.")
    },
    [NS("Thomas Edison")] = {
        NS("I have not failed. I've just found 10,000 ways that won't work.")
    },
    [NS("Woody Allen")] = {
        NS("I'm not afraid of death;\nI just don't want to be there when it happens.")
    },
    [NS("Bill Watterson")] = {
        NS("Reality continues to ruin my life.")
    },
    [NS("Oscar Levant")] = {
        NS("There's a fine line between genius and insanity.\nI have erased this line.")
    },
    [NS("Dr. Seuss")] = { -- Theodor Seuss Geisel
        NS("They say I'm old-fashioned, and live in the past,\nbut sometimes I think progress progresses too fast!")
    },
    -- British
    [NS("Arthur C. Clarke")] = {
        NS("It has yet to be proven that intelligence has any survival value."),
        NS("The only way of discovering the limits of the possible\nis to venture a little way past them into the impossible."),
    },
    [NS("Bear Grylls")] = {
        NS("That fine line between bravery and stupidity is endlessly debated\n– the difference really doesn’t matter.")
    },
    [NS("Winston Churchill")] = {
        NS("If you're going through hell, keep going")
    },
    [NS("George Orwell")] = {
        NS("Progress is not an illusion; it happens,\nbut it is slow and invariably disappointing.")
    },
    [NS("The Black Knight")] = { -- Monty Python lol
        NS("Tis but a scratch!")
    },
    [NS("William Shakespeare")] = {
        NS("I like this place and could willingly waste my time in it.")
    },
    [NS("Isaac Newton")] = {
        NS("Nature is pleased with simplicity. And nature is no dummy.")
    },
    [NS("Tolkien")] = {
        NS("Not all those who wander are lost.")
    },
    [NS("Terry Pratchett")] = {
        NS("Give a man a fire and he's warm for a day,\nbut set fire to him and he's warm for the rest of his life.")
    },
    [NS("Douglas Adams")] = {
        NS("Let's think the unthinkable, let's do the undoable.\nLet us prepare to grapple with the ineffable itself, and see if we may not eff it after all.")
    },
    [NS("Virginia Woolf")] = {
        NS("One cannot think well, love well, sleep well, if one has not dined well.")
    },
    [NS("Dylan Thomas")] = { -- Welsh
        NS("Do not go gentle into that good night.\nRage, rage against the dying of the light.")
    },
    [NS("Robert Swan")] = {
        NS("The greatest threat to our planet\nis the belief that someone else will save it.")
    },
    -- French
    [NS("Victor Hugo")] = {
        NS("Emergencies have always been necessary to progress.")
    },
    [NS("Albert Camus")] = {
        NS("There is scarcely any passion without struggle.")
    },
    [NS("Marthe Troly-Curtin")] = { -- I think she's French
        NS("Time you enjoy wasting is not wasted time.")
    },
    -- German (Germany + Austria + Bohemia)
    [NS("Franz Kafka")] = {
        NS("I only fear danger where I want to fear it.")
    },
    [NS("Friedrich Nietzsche")] = {
        NS("All truly great thoughts are conceived while walking."),
        NS("When we are tired, we are attacked by ideas we conquered long ago."),
        NS("He who has a strong enough why can bear any how.")
    },
    [NS("Markus Herz")] = {
        NS("Be careful about reading health books.\nSome fine day you'll die of a misprint.")
    },
    -- Spanish
    [NS("Balthasar Gracian")] = {
        NS("There are rules to luck, not everything is chance for the wise;\nluck can be helped by skill.")
    },
    -- Maltese
    [NS("Edward de Bono")] = {
        NS("It will be a sinister day when computers start to laugh,\nbecause that will mean they are capable of a lot of other things as well."),
        NS("Po converts what might otherwise be taken as madness\ninto a perfectly reasonable illogical procedure.")
    },
    -- Nordic
    [NS("Soren Kierkegaard")] = { -- Danish
        NS("Life can only be understood backwards; but it must be lived forwards."),
    },
}

local function get_quote()
    local author = {}
    for i,_ in pairs(quote_list) do
        -- manually make a list of the quote_list indexes (authors)
        author[#author + 1] = i
    end
    author = author[math.random(1,#author)] -- get an author
    -- and get a quote
    local quote = quote_list[author]
    quote = quote[math.random(1,#quote)]

    author = S(author)
    quote = S(quote)

    quote = '"'..quote..'"' -- add speech quotes to the quote
    quote = quote.."\n\n- "..author -- create quote-author string

    return quote
end

-- generate break_taker's formspec
-- return formspec string
local function get_formspec()
    local title = S("BREAK TIME!")
    local message1 =
        S("You've been here long enough to justify a real break.\n"..
          "Think of this as a reminder from your better self.\n"..
          "Go get some rest. "..
          "Leave Exile behind. You can come back any time.")
    local quote = get_quote()

    local formspec = {
        "size[16,10.5]"..
            "real_coordinates[true]",
        -- exit button
        "button_exit[15,0.2;0.8,0.75;exit_form;X]"..
        -- title
        "label[7,1;", minetest.formspec_escape(title), "]",
        -- general message
        "label[2.375,2.5;", minetest.formspec_escape(message1), "]",
        -- random quote for fun
        "label[2.375,5;", minetest.formspec_escape(quote), "]",
        -- disable breaktaker checkbox
        "checkbox[5.75,8.2;breaktaker;  "
        ..S("Disable Break-taker popup")..";"
        .. tostring(false).."]" -- should be unchecked if we see the formspec
    }

    return table.concat(formspec, "")
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "bed_rest:break_taker" then -- not our form
		return false
	else
        if fields.breaktaker then
            local setting = (fields.breaktaker == "false")

            local meta = player:get_meta()
            meta:set_string("breaktaker", tostring(setting))
            -- not sure it does something
            -- copied from exile_game/playersetting.lua
            EXILE.setting_changed(player, "breaktaker", setting, meta)
        end
    end
end)

--check session length and encourage player to take a real break
function bed_rest.break_taker(name, enabled)
    local ts = bed_rest.session_start[name]
    local sess_l =  bed_rest.session_limit[name]
    local tn = os.time()

    local nobreak = minetest.settings:get_bool('exile_nobreaktaker') or false
    if enabled == "false" or ( enabled == "" and nobreak == true ) then
        return
    end

    if os.difftime(tn, ts) > sess_l then
        --show form
        minetest.show_formspec(name, "bed_rest:break_taker", get_formspec())
        minetest.after(0.75, function()
                           minetest.sound_play("bed_rest_breakbell",
                                               {to_player = name, gain = 0.8})
        end)
        --reset clock, with a diminishing limit
        --if ignored too long it will eventually become a constant nag
        --e.g. 30 + 15 + 7.5 + 3.25 + 1.125 = ~ 1hr max
        bed_rest.session_start[name] = tn
        bed_rest.session_limit[name] = sess_l/2
    end
end
