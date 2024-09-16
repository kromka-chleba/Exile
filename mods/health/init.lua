-------------------------------------
--HEALTH

--[[
    Two global step functions
    Fast, and slow.

    Fast applies environmental and action based effects (in on_actions)
    Slow applies internal metabolism effects (here)
]]

------------------------------------

HEALTH = {}
sfinv = sfinv
player_monoids = player_monoids
clothing = clothing

-- Internationalization
HEALTH.S = minetest.get_translator("health")
HEALTH.FS = function(...)
    return minetest.formspec_escape(HEALTH.S(...))
end

dofile(minetest.get_modpath('health')..'/health_states.lua')
dofile(minetest.get_modpath('health')..'/health_effects.lua')
dofile(minetest.get_modpath('health')..'/on_actions.lua')
dofile(minetest.get_modpath('health')..'/hud.lua')
dofile(minetest.get_modpath('health')..'/food.lua')


--frequency of updating and applying effects
local interval = 60

local function is_meta(meta)
    if type(meta) == "userdata" then
        if meta["get_int"] and meta["get_string"] then
            return true
        end
    end
end

-- minimal/utility/general.lua
local function math_clamp(num,min,max)
    return minimal.math_clamp(num,min,max)
end

------------------------------------------------------------------
--SOUND HANDLING
------------------------------------------------------------------
local player_sounds = {}

-- does not remove sounds after they played
function HEALTH.append_sound(player,handle)
    if not minetest.is_player(player) or not type(handle) == "number" then
        -- be certain that proper values are sent
        return
    end
    local index = player_sounds[player]
    if not index then
        -- create an index for the player
        index = {}
        player_sounds[player] = index
    end
    table.insert(index,handle)
end

function HEALTH.stop_sounds(player)
    if not minetest.is_player(player) or not player_sounds[player] then
        -- no index (or not player), return
        return
    end
    for _,handle in pairs(player_sounds[player]) do
        -- stop all sounds
        minetest.sound_stop(handle)
    end
    player_sounds[player] = nil
end

-----------------------------
--Player Attributes
--
--use standard values base, so it doesn't compound each time called
--Only adjusted values saved in player meta so they can be accessed without recalculating
--cf hunger etc which do get change and have no base value
HEALTH.max_hp = 20
function HEALTH.get_default_attributes()
    -- returns base attributes of a fresh player
    return {
        health = HEALTH.max_hp,
        thirst = 100,
        hunger = 1000,
        energy = 1000,
        temperature = 37,
        oxygen = 10, -- for suffocation or drowning

        heal_rate = 1, -- 4
        thirst_rate = -1,
        hunger_rate = -3, -- -2
        recovery_rate = 4, -- 5

        move = 0,
        jump = 0,

        --no clothing temperature comfort zone
        clothing_temp_min = 18, -- 20
        clothing_temp_max = 32, -- 30
    }
end

--e.g. for new players
function HEALTH.set_default_attributes(player)
    local meta = player:get_meta()
    local attrb = HEALTH.get_default_attributes()
    player:set_hp(attrb.health)
    for name,value in pairs(attrb) do
        if (type(name) ~= "string") then
            name = tostring(name)
        end
        if (type(value) == "number" and name ~= "health") then
            -- don't try to set an int for health

            value = math.ceil(value)
            meta:set_int(name,value)
        elseif (type(value) == "string") then
            meta:set_string(name,value)
        end
    end
    local st = player_api.get_state(player)
    st:add("thirst", attrb.thirst)
    st:add("hunger", attrb.hunger)
    st:add("energy", attrb.energy)
    st:add("int_temp", attrb.temperature)
end
function HEALTH.reset_attributes(...)
    HEALTH.set_default_attributes(...)
end

-- MISCELLANEOUS GET FUNCTIONS

function HEALTH.get_meta_stats(meta)
    assert(type(meta) == "userdata",
           "health.get_meta_stats: meta/player is not a valid 'userdata'")
    if (minetest.is_player(meta)) then
        meta = meta:get_meta()
    elseif not is_meta(meta) then
        error("health.get_meta_stats: invalid parameter given for meta/player")
    end
    local stats = {
        thirst = meta:get_int("thirst"),
        hunger = meta:get_int("hunger"),
        energy = meta:get_int("energy"),
        temperature = meta:get_int("temperature"),
        heal_rate = meta:get_int("heal_rate"),
        thirst_rate = meta:get_int("thirst_rate"),
        hunger_rate = meta:get_int("hunger_rate"),
        recovery_rate = meta:get_int("recovery_rate"),
        lives = meta:get_int("lives"),
        move = meta:get_int("move"),
        jump = meta:get_int("jump"),
        clothing_temp_min = meta:get_int("clothing_temp_min"),
        clothing_temp_max = meta:get_int("clothing_temp_max"),
    }

    return stats
end

function HEALTH.set_meta_stats(player, stats, meta)
    if not meta then meta = player:get_meta() end
    if not stats or not stats.thirst then
        error("No stats given to set_meta_stats")
    end
    meta:set_int("thirst", stats.thirst)
    meta:set_int("hunger", stats.hunger)
    meta:set_int("energy", stats.energy)
    meta:set_int("temperature", stats.temperature)
    meta:set_int("heal_rate", stats.heal_rate)
    meta:set_int("thirst_rate", stats.thirst_rate)
    meta:set_int("hunger_rate", stats.hunger_rate)
    meta:set_int("recovery_rate", stats.recovery_rate)
    meta:set_int("lives", stats.lives)
    meta:set_int("move", stats.move)
    meta:set_int("jump", stats.jump)
    meta:set_int("clothing_temp_min", stats.clothing_temp_min)
    meta:set_int("clothing_temp_max", stats.clothing_temp_max)
end


function HEALTH.get_player_stats(player, meta)
    assert(minetest.is_player(player) == true,
           "get_player_stats: 'player' is not a player")
    if not meta then meta = player:get_meta() end
    local fields = HEALTH.get_meta_stats(meta)
    fields.health = player:get_hp()
    return fields
end

function HEALTH.set_player_stats(player, stats, meta)
    if not meta then meta = player:get_meta() end
    if not stats or not stats.thirst then
        error("No stats given to set_player_stats")
    end
    player:set_hp(stats.health)
    HEALTH.set_meta_stats(player, stats, meta)
end

function HEALTH.get_life_num(meta) -- gets player's "lives" and returns it
    if type(meta) ~= "userdata" then
        -- "HEALTH.get_life_num: invalid argument for 'meta/player'"
        return 0
    end
    if (minetest.is_player(meta)) then
        meta = meta:get_meta()
    end
    if not is_meta(meta) then
        -- "HEALTH.get_life_num: could not get metadata"
        return 0
    end

    return meta:get_int("lives") or 0
end

-- SETTING AND MODIFYING FUNCTIONS

-- allows any code that depends on HEALTH to use modify_hp
--   to reliably modify player health
function HEALTH.modify_hp(player,value)
    assert(minetest.is_player(player) == true,
           "health.modify_hp: 'player' is not a player")
    if (type(value) ~= "number") then
        value = 0
    end
    local phealth = player:get_hp()
    phealth = math_clamp(phealth + value,0,HEALTH.max_hp)
    player:set_hp(phealth)

    return phealth -- return modified health
end

-- sets meta values between certain limits and updates meta
function HEALTH.set_int(meta,name,value)
    assert(type(meta) == "userdata",
           "health.set_int: meta/player is not a valid 'userdata'")
    if (minetest.is_player(meta)) then
        meta = meta:get_meta()
    end
    assert(is_meta(meta),
           "health.set_int: invalid first parameter given for meta/player")
    if (type(value) ~= "number") then
        value = 0
    end

    if (type(name) ~= "string") then
        name = tostring(name)
        name = string.lower(name)
    else
        name = string.lower(name)
    end
    if (meta:get(name) == nil) then
        return 0
    end

    value = math.ceil(value)
    -- check for names to set custom limits
    if (name == "hunger" or name == "energy") then
        value = math_clamp(value,0,1000)
    elseif (name == "thirst" or name == "temperature") then
        value = math_clamp(value,0,100)
    end
    meta:set_int(name,value)

    return value -- return provided value
end

-- allows any code that depends on HEALTH to use modify_int
--   to reliably modify stats like hunger or thirst
function HEALTH.modify_int(meta,name,value)
    assert(type(meta) == "userdata",
           "health.modify_int: player/meta is not a valid 'userdata'")
    if minetest.is_player(meta) then
        meta = meta:get_meta()
    end
    assert(is_meta(meta),
           "health.modify_int: invalid first parameter given for player/meta")
    if (type(value) ~= "number") then
        value = 0
    end

    if (type(name) ~= "string") then
        name = tostring(name)
        name = string.lower(name)
    else
        name = string.lower(name)
    end
    if (meta:get(name) == nil) then -- if key doesn't exist
        return 0
    end

    local stat = meta:get_int(name)
    value = math.ceil(value) -- no floats

    return HEALTH.set_int(meta,name,(stat + value))
    -- return modified value (use set_int to keep metadata within limits)
end



----------------------------
-- Health Calc (calculation) (does not calculate illness) -- called to update player's status
-- calculates player status in reference to the player's stats and health, saves adjusted rates
-- returns the adjusted rates so they can be used if desired
-- dontset will prevent setting the variables
function HEALTH.health_calc(player,meta,dontset)
    assert(minetest.is_player(player) == true,
           "health.health_calc: provided 'player' is not a player!")

    if ( not type(dontset) == "boolean" ) then
        dontset = false
    end
    local pname = player:get_player_name()
    local bstats = HEALTH.get_default_attributes() -- get base starting stats
    local stats

    -- incase meta is not provided then (get it! :D)
    if not is_meta(meta) then
        meta = player:get_meta()
    end
    stats = HEALTH.get_meta_stats(meta)

    -- player's current stats as variables
    local health = player:get_hp()
    local energy = stats.energy
    local hunger = stats.hunger
    local thirst = stats.thirst
    local temperature = stats.temperature

    -- base stats to prevent compounding
    local h_rate = bstats.heal_rate
    local t_rate = bstats.thirst_rate
    local hun_rate = bstats.hunger_rate
    local r_rate = bstats.recovery_rate
    local mov = bstats.move
    local jum = bstats.jump

    --(hunger/Energy has 10x stock)
    --0-20 starving/severe dehydrated: malus, no heal
    --20-40 malnourished/dehydrated: malus
    --40-60 hungry/thirsty: small malus
    --60-80 good:
    --80-100 overfull: small malus

    --80-100 well rested. bonus
    --60-80 rested.
    --40-60 tired. small malus
    --20-40 fatigued. malus
    --0-20 exhausted. malus no heal

    --<27 death
    --27-32: severe hypo. malus no heal
    --32-37: hypothermia. malus
    --36-38: normal
    --38-43: hyperthermia. malus.
    --43-47: severe heat stroke. malus no heal
    -->47 death

    --
    --update rates
    --

    --bonus/malus from health
    --  (old calculations by dokimi, I have not touched these - TPH)
    if health <= 1 then
        mov = mov - 50
        jum = jum - 50
        h_rate = h_rate - 3
        r_rate = r_rate - 4
    elseif health < 4 then
        mov = mov - 25
        jum = jum - 25
        h_rate = h_rate - 2
        r_rate = r_rate - 2
    elseif health < 8 then
        mov = mov - 20
        jum = jum - 20
        h_rate = h_rate - 1
        r_rate = r_rate - 1
    elseif health < 12 then
        mov = mov - 15
        jum = jum - 15
    elseif health < 16 then
        mov = mov - 10
        jum = jum - 10
    end

    --bonus/malus from energy
    if energy > 800 then
        h_rate = h_rate + 2
        mov = mov + 15
        jum = jum + 15
    elseif energy < 1 then
        h_rate = h_rate - 1
        mov = mov - 40
        jum = jum - 40
        t_rate = t_rate - 12
        hun_rate = hun_rate - 24
    elseif energy < 200 then
        h_rate = h_rate - 1
        mov = mov - 20
        jum = jum - 20
        t_rate = t_rate - 4
        hun_rate = hun_rate - 8
    elseif energy < 400 then
        mov = mov - 10
        jum = jum - 10
        t_rate = t_rate - 3
        hun_rate = hun_rate - 4
    elseif energy < 600 then
        mov = mov - 5
        jum = jum - 5
        t_rate = t_rate - 2
        hun_rate = hun_rate - 2
    elseif energy < 700 then
        hun_rate = hun_rate - 1
    end


    --bonus/malus from thirst
    if thirst > 80 then
        h_rate = h_rate + 1
        r_rate = r_rate + 2
        mov = mov + 1
        jum = jum + 1
    elseif thirst < 1 then
        h_rate = h_rate - 12
        r_rate = r_rate - 10
        mov = mov - 30
        jum = jum - 30
    elseif thirst < 20 then
        h_rate = h_rate - 2
        r_rate = r_rate - 2
        mov = mov - 20
        jum = jum - 20
    elseif thirst < 40 then
        h_rate = h_rate - 1
        r_rate = r_rate - 1
        mov = mov - 10
        jum = jum - 10
    elseif thirst < 60 then
        mov = mov - 1
        jum = jum - 1
    end

    --bonus/malus from hunger
    if hunger > 800 then
        h_rate = h_rate + 1
        r_rate = r_rate + 2
        mov = mov + 1
        jum = jum + 1
    elseif hunger < 1 then
        h_rate = h_rate - 12
        r_rate = r_rate - 10
        mov = mov - 30
        jum = jum - 30
    elseif hunger < 200 then
        h_rate = h_rate - 2
        r_rate = r_rate - 2
        mov = mov - 20
        jum = jum - 20
    elseif hunger < 400 then
        h_rate = h_rate - 1
        r_rate = r_rate - 1
        mov = mov - 10
        jum = jum - 10
    elseif hunger < 600 then
        mov = mov - 1
        jum = jum - 1
    end

    local st = player_api.get_state_by_name(pname)
    st:set_progress("int_temp", temperature)
    local l = st:get_severity("int_temp") - 4

    local effect = HEALTH.internal_temp_table[math.abs(l)]

    h_rate = h_rate + effect.h_adj
    r_rate = r_rate + effect.r_adj
    mov = mov + effect.mov_adj
    jum = jum + effect.mov_adj

    local sev = math.abs(l)

    if l > 0 then
        st:add_basic("bodytemp", HEALTH.S("Hyperthermia"), 3, sev)
    elseif l < 0 then
        st:add_basic("bodytemp", HEALTH.S("Hypothermia"), 3, sev)
    elseif st:is("bodytemp") then
        st:clear("bodytemp")
    end

    -- update stats
    stats.heal_rate = h_rate
    stats.thirst_rate = t_rate
    stats.hunger_rate = hun_rate
    stats.recovery_rate = r_rate
    stats.move = mov
    stats.jump = jum
    -- set player's meta
    if not dontset then
        for name,value in pairs(stats) do
            if (type(value) == "number") then
                HEALTH.set_int(meta,name,value)
            elseif (type(value) == "string") then
                meta:set_string(value)
            end
        end
    end

    --return adjusted rates so can be applied if necessary
    return stats
end
-----------------------------

-- HEALTH.quick_physics
-- does what HEALTH.health_calc does, but only for move and jump
function HEALTH.quick_physics(player,meta)
    local stats = HEALTH.health_calc(player,meta,true)

    local pname = player:get_player_name()
    if not bed_rest.player[pname] then
        player_monoids.speed:add_change(player, 1 + (stats.move/100),
                                        "health:physics")
        player_monoids.jump:add_change(player, 1 + (stats.jump/100),
                                       "health:physics")
    end
    return stats
end




--[[
    -----------------------------
    --Forms for sfinv
    --only for bug testing


    --get data and create form
    local function sfinv_get(self, player, context)
    local meta = player:get_meta()

    local player_pos = player:get_pos()
    player_pos.y = player_pos.y + 0.6 --adjust to body height
    local enviro_temp = tostring(math.floor(climate.get_point_temp(player_pos)))

    local health = tostring(player:get_hp())
    local thirst = tostring(meta:get_int("thirst"))
    local hunger = tostring(meta:get_int("hunger"))
    local energy = tostring(meta:get_int("energy"))
    local temperature = tostring(meta:get_int("temperature"))
    local heal_rate = tostring(meta:get_int("heal_rate"))
    local thirst_rate = tostring(meta:get_int("thirst_rate"))
    local hunger_rate = tostring(meta:get_int("hunger_rate"))
    local recovery_rate = tostring(meta:get_int("recovery_rate"))
    local move = tostring(meta:get_int("move"))
    local jump = tostring(meta:get_int("jump"))



    local formspec = "label[0.1,0.1; Health: " .. health .. " / 20]"..
    "label[0.1,0.6; Thirst: " .. thirst .. " / 100]"..
    "label[0.1,1.1; Hunger: " .. hunger .. " / 1000]"..
    "label[0.1,1.6; Energy: " .. energy .. " / 1000]"..
    "label[0.1,2.1; Body Temperature: " .. temperature .. " C]"..
    "label[0.1,3.1; Move Speed: " .. move .. " % change]"..
    "label[0.1,3.6; Jumping: " .. jump .. " % change]"..

    "label[4,0.1; Heal Rate: " .. heal_rate .. " ]"..
    "label[4,0.6; Thirst Rate: " .. thirst_rate .. " ]"..
    "label[4,1.1; Hunger Rate: " .. hunger_rate .. " ]"..
    "label[4,1.6; Recovery Rate: " .. recovery_rate .. " ]"..
    "label[4,2.1; External Temperature: " .. enviro_temp .. " C]"..
    "button[4,3.1;1,1;toggle_health_hud;HUD]"
    --..
    --"textarea[0.5,5.1;6,6;;Active Effects:;"..active_list.." ]"

    return formspec
    end



    local function register_tab()
    sfinv.register_page("health:health_tab", {
    title = "Health",
    on_enter = function(self, player, context)
    sfinv.set_player_inventory_formspec(player)
    end,
    get = function(self, player, context)
    local formspec = sfinv_get(self, player, context)
    return sfinv.make_formspec(player, context, formspec, true)
    end
    })
    end

    register_tab()


]]

-----------------------------
--Applies Health Effects
--called by malus_bonus
--runs through player's current effects, runs the function for that effect
--takes all the same variables, and outputs as any effect may use them.
--adjusted outputs feed back into malus_bonus
local function do_effects_list(player, meta, stats)

    local effects_list = meta:get_string("effects_list")
    effects_list = minetest.deserialize(effects_list) or {}

    if #effects_list > 0 then
        for key, effect in ipairs(effects_list) do

            local name = effect[1]
            local order = effect[2]
            local valid = false

            ----------
            if name == "Food Poisoning" then
                stats = HEALTH.food_poisoning(order, player, meta,
                                              effects_list, stats)
                valid = true
            end
            ----------
            if name == "Fungal Infection" then
                stats = HEALTH.fungal_infection(order, player, meta,
                                                effects_list, stats)
                valid = true
            end
            ----------
            if name == "Dust Fever" then
                stats = HEALTH.dust_fever(order, player, meta,
                                          effects_list, stats)
                valid = true
            end
            ----------
            if name == "Drunk" then
                stats = HEALTH.drunk(order, player, meta,
                                     effects_list, stats)
                valid = true
            end
            ----------
            if name == "Hangover" then
                stats = HEALTH.hangover(order, player, meta,
                                        effects_list, stats)
                valid = true
            end
            ----------
            if name == "Intestinal Parasites" then
                stats = HEALTH.intestinal_parasites(order, player, meta,
                                                    effects_list, stats)
                valid = true
            end
            ----------
            if name == "Tiku High" then
                stats = HEALTH.tiku_high(order, player, meta,
                                         effects_list, stats)
                valid = true
            end
            ----------
            if name == "Neurotoxicity" then
                stats = HEALTH.neurotoxicity(order, player, meta,
                                             effects_list, stats)
                valid = true
            end
            ----------
            if name == "Hepatotoxicity" then
                stats = HEALTH.hepatotoxicity(order, player, meta,
                                              effects_list, stats)
                valid = true
            end
            ----------
            if name == "Photosensitivity" then
                stats = HEALTH.photosensitivity(order, player, meta,
                                                effects_list, stats)
                valid = true
            end
            ---------
            if name == "Meta-Stim" then
                stats = HEALTH.meta_stim(order, player, meta,
                                         effects_list, stats)
                valid = true
            end

            if valid == false then
                table.remove(effects_list, key)
            end
        end
    end

    -- update effects_list
    meta:set_string("effects_list",
                    minetest.serialize(effects_list))
    meta:set_int("effects_num", #effects_list)

    return stats
end





-----------------------------
--Bonus Malus... so can be called whenever player status is changed
--takes standard rates and adjusts them based on player status.
--saves adjusted rates and applies physics.
--send it attributes to adjust by,
--also give name and meta, bc anything calling it should already have that
-- returns the adjusted rates so they can be used if desired
--
function HEALTH.malus_bonus(player,meta)
    local stats = HEALTH.health_calc(player,meta)
    -- get mov + jum before do_effects
    local mov = stats.move
    local jum = stats.jump

    stats = do_effects_list(player,meta,stats) -- update for health effects
    -- set player's meta to diseased
    for name,value in pairs(stats) do
        if (type(value) == "number" and name ~= "move" or name ~= "jump") then
            HEALTH.set_int(meta,name,value)
        elseif (type(value) == "string") then
            meta:set_string(value)
        end
    end

    local pname = player:get_player_name()
    if not bed_rest.player[pname] then
        --split physics from hunger etc from that from health effects
        --  this means health_calc can fiddle with one half,
        --  without overriding the half from effects
        mov = stats.move - mov
        jum = stats.jump - jum
        player_monoids.speed:add_change(player, 1 + (mov/100), "health:physics_HE")
        player_monoids.jump:add_change(player, 1 + (jum/100), "health:physics_HE")
    end

    return stats
end
-----------------------------


-----------------------------
--Main
--
minetest.register_on_newplayer(function(player)
        HEALTH.set_default_attributes(player)
end)

function HEALTH.update_player_physics(player)
    local meta = player:get_meta()
    HEALTH.malus_bonus(player,meta)
end

minetest.register_on_joinplayer(function(player)
        --set physics etc
        HEALTH.update_player_physics(player)
        local meta = player:get_meta()
        local thirst = meta:get_int("thirst")
        local hunger = meta:get_int("hunger")
        local energy = meta:get_int("energy")
        local temperature = meta:get_int("temperature")
        local st = player_api.get_state(player)
        st:add("int_temp", temperature)
        st:add("energy", energy)
        st:add("hunger", hunger)
        st:add("thirst", thirst)

        local velo = meta:get_string("player_velocity")
        if velo ~= nil then
            local velo_vec = minetest.string_to_pos(velo)
            if velo_vec ~= nil then
                player:add_velocity(velo_vec)
            end
            meta:set_string("player_velocity", "")
        end
        -- update player's form to display thoses settings
        sfinv.set_player_inventory_formspec(player)
end)

minetest.register_on_dieplayer(function(player)
        --redo physics (to clear what killed them)
        player_monoids.speed:del_change(player, "health:physics")
        player_monoids.jump:del_change(player, "health:physics")
        player_monoids.speed:del_change(player, "health:physics_HE")
        player_monoids.jump:del_change(player, "health:physics_HE")
        --clear Health effects list
        local meta = player:get_meta()
        meta:set_string("effects_list", "")
        meta:set_int("effects_num", 0)
        -- stop all sounds
        HEALTH.stop_sounds(player)
end)

minetest.register_on_respawnplayer(function(player)
        HEALTH.set_default_attributes(player)
        player_api.reset_equipment_effects(player)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
        --TODO: Find a way to save this on singleplayer or for 1st hosted player
        local meta = player:get_meta()
        local velo = player:get_velocity() or player:get_player_velocity()
        meta:set_string("player_velocity", minetest.pos_to_string(velo))
end)

if minetest.settings:get_bool("enable_damage") == false then return end

--Main update values
local timer = 0


minetest.register_globalstep(function(dtime)
        timer = timer + dtime

        --run
        if timer > interval then
            for _,player in pairs(minetest.get_connected_players()) do
                local meta = player:get_meta()
                local name = player:get_player_name()
                local health = player:get_hp()
                -- don't damage us if we're already dead
                if health > 0 and
                    player:get_armor_groups().immortal ~= 1 then

                    --apply rate adjustments for current player status

                    local stats = HEALTH.malus_bonus(player,meta)
                    local thirst
                    local hunger
                    local energy
                    local temperature = stats.temperature

                    --apply rate adjustments for current player status
                    local h_rate = stats.heal_rate
                    local hun_rate = stats.hunger_rate
                    local t_rate = stats.thirst_rate
                    local r_rate = stats.recovery_rate

                    --update
                    local temperature1 = 0
                    if temperature > 37 then
                        temperature1 = temperature1 - 1
                        if temperature > 47 then
                            h_rate = h_rate -1
                        end
                    elseif temperature < 37 then
                        temperature1 = temperature1 + 1
                        if temperature < 27 then
                            h_rate = h_rate -1
                        end
                    end

                    --update
                    HEALTH.modify_hp(player,h_rate)
                    temperature = HEALTH.modify_int(
                        meta,"temperature",temperature1)
                    thirst = HEALTH.modify_int(meta,
                                               "thirst",t_rate)
                    hunger = HEALTH.modify_int(meta,
                                               "hunger",hun_rate)
                    energy = HEALTH.modify_int(meta,"energy",r_rate)

                    local st = player_api.get_state_by_name(name)
                    st:set_progress("int_temp", temperature)
                    st:set_progress("energy", energy)
                    st:set_progress("hunger", hunger)
                    st:set_progress("thirst", thirst)

                    --update form so can see change while looking
                    sfinv.set_player_inventory_formspec(player)
                end
            end
        end
        --reset
        if timer > interval then
            timer = 0
        end
end)
