-----------------------------------------------------------------
--BED REST FUNCTIONS
--
-----------------------------------------------------------------
local S = minetest.get_translator("bed_rest")
local NS = function(s) return s end

local pi = math.pi
--silence luacheck warnings about accessing globals:
bed_rest = bed_rest
local store = bed_rest.store

player_api = player_api
player_monoids = player_monoids
clothing = clothing
minimal = minimal

-- after this many IRL days, beds in multiplayer will no longer be protected
local days_until_timeout = 7

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


local function get_formspec()
    local title = S("BREAK TIME!")
    local message1 =
        S("You've been here long enough to justify a real break.\n"..
          "Think of this as a reminder from your better self.\n"..
          "Go get some rest. "..
          "Leave Exile behind. You can come back any time.")
    local quote = get_quote()

    local formspec = {
        "size[19.5,13]"..
            "real_coordinates[true]",
        "label[9.375,1.5;", minetest.formspec_escape(title), "]",
        "label[2.375,3.5;", minetest.formspec_escape(message1), "]",
        "label[2.375,7.5;", minetest.formspec_escape(quote), "]",
    }

    return table.concat(formspec, "")
end

--check session length and encourage player to take a real break
local function break_taker(name, enabled)
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

local function blanket_find(inv,listName)
    local cinv = inv:get_list(listName)
    for stkidx,itemstk in pairs(cinv) do
        if not (itemstk:is_empty()) then
            if minetest.get_item_group(itemstk:get_name(),"blanket") > 0 then
                if itemstk:get_count() > 1 then
                    -- prevent the allowance of 2 blankets being transferred at once
                    local old_itemstk = itemstk
                    itemstk = itemstk:take_item(1)
                    inv:set_stack(listName,stkidx,old_itemstk)
                else
                    -- using "remove_item" causes colour domination due to itemstring issues I imagine
                    inv:set_stack(listName,stkidx,ItemStack(''))
                end

                return itemstk
            end
        end
    end
    return nil
end

local function blanket_put(newstack,inv,listName)
    if inv:room_for_item(listName,newstack) then
        local tinv = inv:get_list(listName)
        for stkidx,stack in pairs(tinv) do
            if stack:is_empty() then
                inv:set_stack(listName,stkidx,newstack)
                return true
            end
        end
    end
    return false
end

--grab_blanket(inv = clothing_inv, list = "clothing") for removal
-----------------------------------------------------------------
local function wear_blanket(player, bed_pos, donning)
    local bed_meta = minetest.get_meta(bed_pos)
    local bedInv = bed_meta:get_inventory()
    bedInv:set_size('main',1)

    local name = player:get_player_name()
    local plyrInv = player:get_inventory()
    local frominvl = "cloths"  local toinvl = "main" local putInv = bedInv
    local newstack

    if donning then
        frominvl = "main"
        toinvl = "cloths"
        putInv = plyrInv
        newstack = bedInv:get_stack('main',1)
        if not newstack:is_empty() then
            -- remove it
            bedInv:set_stack('main',1,ItemStack(''))
        else
            -- Find one in players inventory
            newstack = blanket_find(plyrInv, frominvl)
        end
    else
        -- Find it in players 'cloths' inventory
        newstack = blanket_find(plyrInv,frominvl)
    end

    if newstack and not newstack:is_empty() then
        bed_meta:set_string("blanket",S("Bed: Contains Blanket"))
        --We have a blanket, put it someplace
        if blanket_put(newstack, putInv, toinvl) then
            newstack = ItemStack('')
            --bedInv:set_stack('main',1,ItemStack(''))
        elseif donning then -- can't put it on, return it to bed or main inventory
            if bedInv:add_item(frominvl, newstack) ~= nil then
                -- Cant add to bed, add to player
                newstack = plyrInv:add_item(frominvl, newstack)
            end
        elseif blanket_put(newstack, plyrInv, toinvl) then
            -- failed to put it in bed inventory, try players
            newstack = ItemStack('')
            --bedInv:set_stack('main',1,ItemStack(''))
        end
        if not newstack:is_empty() then
            --drop it at our feet if there's no room when taking it off
            local ppos = player:get_pos()
            minetest.item_drop(newstack, player, ppos)
            minetest.chat_send_player(
                name, S("You have no room to hold your blanket, so you drop it."))
            minetest.sound_play("nodes_nature_dig_snappy",
                                {pos = ppos, gain = .8, max_hear_distance = 2})
        end
    else -- assume we're removing blanket
        bed_meta:set_string("blanket","")
    end
    if not bedInv:is_empty('main') then
        minimal.infotext_set_new(bed_pos, bed_meta)
    end
    clothing:update_temp(player)
    player_api.set_texture(player)
end

-----------------------------------------------------------------
local function get_look_yaw(pos)
    local rotation = minetest.get_node(pos).param2
    if rotation > 3 then
        rotation = rotation % 4 -- Mask colorfacedir values
    end
    if rotation == 1 then
        return pi / 2, rotation
    elseif rotation == 3 then
        return -pi / 2, rotation
    elseif rotation == 0 then
        return pi, rotation
    else
        return 0, rotation
    end
end

local bedspot = {
    initial_properties = {collisionbox = {0, -0.025, 0, 0.01, 0.01, 0.01},
                          visual="upright_sprite",
                          textures = { "empty.png" },
                          physical = true
                         },
    on_activate = function(self) -- fall down until we hit the bed, aka pomf
        self.object:set_velocity(vector.new(0,-2,0))
    end,
    on_step = function(self, dtime, moveresult)
        if not self.timer then self.timer = 0.1 return end
        self.timer = self.timer - dtime
        if self.timer > 0 then return end
        self.timer = nil
        self.count = ( self.count or 0 ) + 1
        local chrilden = self.object:get_children()
        if #chrilden < 1 or self.count > 9 then -- cannot frigth back?!
            self.object:remove()
            return
        end
        local player = chrilden[1]
        self.object:set_yaw(player:get_look_horizontal())
    end,
    on_attach_child = function(self, child)
        self.object:set_yaw(child:get_look_horizontal())
    end,
    on_detach_child = function(self, child)
        self.object:remove()
    end
}
minetest.register_entity("bed_rest:bedspot", bedspot)

local function stopmove(player, pos, lives, meta)
    if (not player) or (not player:is_player()) then return end
    if not meta then meta = player:get_meta() end
    if lives then
        local newlives = meta:get_string("lives")
        if lives < tonumber(newlives) then
            return -- Player has died before this fired
        end
    end
    local dropspot = vector.new(pos.x, pos.y + 0.6, pos.z)
    player:set_attach(minetest.add_entity(dropspot, "bed_rest:bedspot"), "")
end


-----------------------------------------------------------------
local function lay_down(player, level, pos, bed_pos, state, skip)
    local name = player:get_player_name()
    local hud_flags = player:hud_get_flags()

    if not player or not name then
        return
    end

    local st = player_api.get_state_by_name(name)

    -- stand up
    if state ~= nil and not state then
        local p = bed_rest.pos[name] or nil
        local bedp = bed_rest.bed_position[name] or nil
        if bedp ~= nil then
            local bed_meta = minetest.get_meta(bedp)
            bed_meta:set_string('status','') -- remove status
            minimal.infotext_clear(bedp, bed_meta)
        end
        bed_rest.player[name] = nil
        bed_rest.level[name] = nil
        st:clear("resting")

        -- skip here to prevent sending player specific changes
        -- (used for players who may have left, and have no player object)
        if skip then
            bed_rest.bed_position[name] = nil
            return
        end

        if p and minimal.safe_landing_spot(p) then
            player:set_pos(p)
        elseif bed_rest.bed_position[name] then
            player:set_pos(bed_rest.bed_position[name])
        end
        bed_rest.bed_position[name] = nil

        --remove blanket
        if bedp then
            wear_blanket(player, bedp, false)
        elseif bed_pos then
            wear_blanket(player, bed_pos, false)
        end

        -- physics, eye_offset, etc
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        player_api.player_attached[name] = false
        player:set_detach()
        player_monoids.speed:del_change(player, "bed_rest:resting")
        player_monoids.jump:del_change(player, "bed_rest:resting")
        player_monoids.gravity:del_change(player, "bed_rest:resting")
        hud_flags.wielditem = true
        player_api.set_animation(player, "stand")

        -- lay down, provided we have a valid bed position
    elseif bed_pos then
        local pmeta = player:get_meta()
        local velo = player:get_velocity() or player:get_player_velocity()
        if velo.x ~= 0 then return end
        if velo.y ~= 0 then return end
        if velo.z ~= 0 then return end
        -- Check if bed is occupied
        for nm, other_pos in pairs(bed_rest.bed_position) do
            if vector.distance(bed_pos, other_pos) < 0.1
                and nm ~= name then
                minetest.chat_send_player(name, S("This bed is already occupied!"))
                local meta = minetest.get_meta(bed_pos)
                minimal.infotext_set_new(bed_pos, meta,
                                         {status=S('Status: Occupied by @1',nm)})
                return false
            end
        end
        bed_rest.pos[name] = pos
        bed_rest.bed_position[name] = bed_pos
        bed_rest.player[name] = 1
        bed_rest.level[name] = level
        st:add("resting")
        if not minetest.is_singleplayer() then
            minimal.infotext_set_new(bed_pos, nil,
                                     {status=S('Status: Occupied by @1', name)})
            minetest.get_node_timer(bed_pos):start(60 * 60 * 24 *
                                                   days_until_timeout)
        end

        --check with break taker
        break_taker(name,player:get_meta():get_string("breaktaker"))

        --wear a blanket from inventory
        wear_blanket(player, bed_pos, true)

        -- physics, eye_offset, etc
        player:set_eye_offset({x = 0, y = -12, z = 0}, {x = 0, y = -4.5, z = 0})
        local yaw, param2 = get_look_yaw(bed_pos)
        player:set_look_horizontal(yaw)
        local dir = minetest.facedir_to_dir(param2)
        local p = {x = bed_pos.x + dir.x / 2, y = bed_pos.y,
                   z = bed_pos.z + dir.z / 2}
        --clear physics
        player_monoids.speed:del_change(player, "health:physics")
        player_monoids.jump:del_change(player, "health:physics")
        player_monoids.speed:del_change(player, "health:physics_HE")
        player_monoids.jump:del_change(player, "health:physics_HE")
        player_monoids.speed:add_change(player, 0, "bed_rest:resting")
        player_monoids.jump:add_change(player, 0, "bed_rest:resting")
        player_monoids.gravity:add_change(player, 0, "bed_rest:resting")
        local lives = tonumber(pmeta:get_string("lives"))
        stopmove(player,p, lives, pmeta)
        player_api.player_attached[name] = true
        hud_flags.wielditem = false
        player_api.set_animation(player, "lay")
    else -- no valid bed pos? put them back. Cut down version of "stand up"
        local p = bed_rest.pos[name] or nil
        if p then -- better hope it's safe, we don't know where your bed is
            player:set_pos(p)
        end
        bed_rest.player[name] = nil
        bed_rest.level[name] = nil
    end

    local brtemp = {}
    brtemp.level = bed_rest.level
    brtemp.player = bed_rest.player
    brtemp.pos = bed_rest.pos
    brtemp.bed_position = bed_rest.bed_position

    store:set_string("bedrest", minetest.serialize(brtemp))
    player:hud_set_flags(hud_flags)
end


--------------------------------------------
function bed_rest.on_rightclick(pos, player, level)
    local name = player:get_player_name()
    local ppos = player:get_pos()

    if bed_rest.player[name] then
        lay_down(player, nil, nil, nil, false)
    else
        -- move to bed
        lay_down(player, level, ppos, pos)
    end
end


--------------------------------------------
function bed_rest.can_dig(bed_pos, player)
    -- Check all players in bed which one is at the expected position
    for nm, player_bed_pos in pairs(bed_rest.bed_position) do
        if vector.equals(bed_pos, player_bed_pos) then
            if minetest.check_player_privs(player, "protection_bypass") then
                --admins can remove old beds
                bed_rest.bed_position[nm] = nil
                return true
            end
            return false
        end
    end
    return true
end

function bed_rest.on_timer(pos, elapsed)
    -- Called after configured timeout to clear bed ownership
    local meta = minetest.get_meta(pos)
    for nm, other_pos in pairs(bed_rest.bed_position) do
        if vector.distance(pos, other_pos) < 0.1 then
            bed_rest.bed_position[nm] = nil
            if not minetest.is_singleplayer() then
                minimal.infotext_set_new(pos, meta,
                                         {status=S('Status: Occupied by @1 (old)',
                                                   nm)})
            end
            return false
        end
    end
end

--------------------------------------------
--Jump out of bed
local jtimer = 0
minetest.register_globalstep(function(dtime)
        jtimer = jtimer + dtime
        if jtimer > 0.2 then
            for _, player in ipairs(minetest.get_connected_players()) do
                local name = player:get_player_name()
                if bed_rest.player[name] then
                    if math.floor(player:get_player_control_bits() / 16) % 2 == 1 then
                        lay_down(player, nil, nil, nil, false) -- jump out of bed
                    end
                end
            end
            jtimer = 0
        end
end)

minetest.register_on_dieplayer(function(player)
        local name = player:get_player_name()
        local hud_flags = player:hud_get_flags()

        bed_rest.player[name] = nil
        bed_rest.bed_position[name] = nil
        bed_rest.level[name] = nil

        -- physics, eye_offset, etc
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        player:set_look_horizontal(math.random(1, 180) / 100)
        player_api.player_attached[name] = false
        player_monoids.speed:del_change(player, "bed_rest:resting")
        player_monoids.jump:del_change(player, "bed_rest:resting")
        player_monoids.gravity:del_change(player, "bed_rest:resting")
        hud_flags.wielditem = true
        player_api.set_animation(player, "stand")

end)

--get start time of session
minetest.register_on_joinplayer(function(player)
        local name = player:get_player_name()
        bed_rest.session_start[name] = os.time()
        -- 30 minutes is 1800 ticks, so multiply by 60
        bed_rest.session_limit[name] =
            minetest.settings:get('exile_breaktime') * 60
        if bed_rest.player[name] then
            lay_down(player, bed_rest.level[name], bed_rest.pos[name],
                     bed_rest.bed_position[name], true)
        end
end
)
