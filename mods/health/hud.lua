----------------------------------------------------------------------
--HUD
----------------------------------------------------------------------

-- Internationalization
HEALTH = HEALTH
local S = HEALTH.S

HEALTH.player_huds = {}
local hud = HEALTH.player_huds
local hudupdateseconds = tonumber(minetest.settings:get("exile_hud_update"))
-- global setting for whether to show stats
local mtshowstats = minetest.settings:get_bool("exile_hud_show_stats") or true
local mthudopacity = minetest.settings:get("exile_hud_icon_transparency") or 127

local hud_type = minimal.hud_type

-- These are color values for the various status levels. They have to be modified
-- per-function below because textures expect one color format and text another.
-- This is a minetest caveat.

-- In texture coloring we simply concat a #.
--              "#"..stat_color

-- In text coloring we concat an 0x and convert the resulting string to a number.
--              tostring("0x"..stat_color)

HEALTH.stat_color = {
    fine = "FFFFFF", -- white
    slight = "FDFF46", -- yellow
    problem = "FF8100", -- orange
    major = "DF0000", -- red
    extreme = "8008FF" -- purple
}
local stat_color = HEALTH.stat_color

local hud_vert_pos      = -128 -- all HUD icon vertical position
local hud_extra_y       = -16  -- pixel offset for hot/cold icons
local hud_text_y        = 32   -- optional text stat offset

local longbarpos = {
    [true] = { ["y"] = 0, ["x"] = 64 },
    [false] = { ["y"] = 80, ["x"] = 0}
}

local hud_health_x      = -300
local hud_hunger_x      = -300
local hud_thirst_x      = -64
local hud_energy_x      = 0
local hud_air_temp_x    = 64
local hud_sick_x        = 300
local hud_body_temp_x   = 300

local icon_scale = {x = 1, y = 1}  -- all HUD icon image scale

wielded_hud = {}
wielded_hud.list = {}

function wielded_hud.register_hudwield(itemname, updatefunc, unwieldfunc)
    -- functions should accept (player, pname, playermeta)
    -- updatefunc should set up and/or update your hud elements
    -- unwieldfunc is called so you can clean up and delete hud elements
    wielded_hud.list[itemname] = { update = updatefunc,
                                   unwield = unwieldfunc }
end

local function tobool(str)
    if str == "true" then
        return true
    end
    return false
end

-- must be ALL string or number
local function concat_text(...)
    return table.concat({...},"")
end

local typelist = { "health", "energy", "thirst", "hunger",
                   "temp", "enviro_temp", "effects" }
function HEALTH.hide_hud_elements(player, meta, list, hide)
    -- Takes a string of elements to hide, or "all", sets them hidden
    -- Needs either player or meta to apply changes to
    -- hide, if true, inverts this function to show elements
    if not core.is_player(player) then
        error("HEALTH.hide_hud_elements: tried to hide hud elements for non-existent (or inactive) player!")
    end
    local hud_data = hud[player:get_player_name()]
    if not hud_data then return end -- no hud data to speak of, return don't error
    meta = type(meta) == "userdata" and meta or player:get_meta()
    -- handle list mechanic
    list = type(list) == "string" and list:lower() or list
    list = type(list) == "string" and list ~= "all" and list:split(",") or list
    list = list == "all" and {"health", "energy", "thirst", "hunger", "body_temp", "enviro_temp", "sick"}
    if list ~= "all" and type(list) ~= "table" then
        error("HEALTH.hide_hude_elements: expected table for list, got type '"..type(list).."'")
    end
    -- now to check through that list
    for _,tag in pairs(list) do
        tag = tag == "temp" and "body_temp" or tag
        -- check if we exist in hud_data, otherwise skip over
        local data = hud_data[tag]
        if data then
            -- remove index with "or nil" if not hidden
            data.hidden = (true ~= hide) or nil
        end
    end
end

function HEALTH.show_hud_elements(player, meta, list)
    HEALTH.hide_hud_elements(player, meta, list, true)
end

function HEALTH.hud_update_settings(player_name, table)
    local hud_data = hud[player_name]
    for nm, val in pairs(table) do
        hud_data[nm] = val
    end
end


local function are_stats_visible(hud_data)
    return (( hud_data.showstats and hud_data.showstats == true ) or
        ( hud_data.showstats == nil and mtshowstats == true ) )
end

function HEALTH.blink_hud_elements(playername, list, setblink, player)
    -- Takes a string of elements or "all", sets them blinking
    -- Needs either playername or player to apply changes to
    -- setblink is the state, true/false/nil
    if not playername and not player then
        error("Tried to blink hud elements for non-existent player!")
    end
    if not playername then playername = player:get_player_name() end
    for i = 1, #typelist do
        if string.match(list, typelist[i]) or string == "all" then
            hud[playername]["blink"][typelist[i]] = setblink
        end
    end
end

local blinkingnow = false
local function blink(bool)
    if not bool or blinkingnow == true then
        return ""
    end
    return "^[multiply:#000000"
end

local stdpos = { x = .5, y = 1}

local function make_image_hud(player, offset, text)
    return player:hud_add({ [hud_type] = "image", scale = icon_scale,
            offset = offset, position = stdpos, text = text })
end

local function make_text_hud(player, offset)
    return player:hud_add{ [hud_type] = "text", offset = offset,
        position = stdpos, text = "" }
end

local setup_hud = function(player)

    player:hud_set_flags({healthbar = false})
    local playername = player:get_player_name()

    local hud_data = {}

    hud[playername] = hud_data
    hud_data.blink = {}

    local meta = player:get_meta()
    hud_data.show_stats = meta:get("exile_hud_show_stats")
    if hud_data.show_stats then -- string to bool, or leave it nil
        hud_data.show_stats = tobool(hud_data.show_stats)
    end

    local lb = tobool(meta:get_string("hud16")) -- nil -> default false

    hud_data.health = {
        image = make_image_hud(player,
            {x = hud_health_x - longbarpos[lb].x,
            y = hud_vert_pos + longbarpos[lb].y},
           "hud_health.png" ),
        text = make_text_hud(player,
            {x = hud_health_x - longbarpos[lb].x,
            y = hud_vert_pos + hud_text_y + longbarpos[lb].y} )
    }

    hud_data.hunger = {
        image = make_image_hud(player,
            {x = hud_hunger_x, y = hud_vert_pos},
            "hud_hunger.png" ),
        text = make_text_hud(player,
            {x = hud_hunger_x,
            y = hud_vert_pos + hud_text_y} )
    }

    hud_data.thirst = {
        image = make_image_hud(player,
            {x = hud_thirst_x, y = hud_vert_pos},
            "hud_thirst.png" ),
        text = make_text_hud(player,
            {x = hud_thirst_x,
            y = hud_vert_pos + hud_text_y} )
    }

    hud_data.energy = {
        image = make_image_hud(player,
            {x = hud_energy_x, y = hud_vert_pos},
            "hud_energy.png" ),
        text = make_text_hud(player,
            {x = hud_energy_x,
            y = hud_vert_pos + hud_text_y} )
    }

    hud_data.body_temp = {
        image = make_image_hud(player,
            {x = hud_body_temp_x, y = hud_vert_pos},
            "hud_body_temp.png" ),
        -- small little icon above our icon
        flare = make_image_hud(player,
            {x = hud_body_temp_x,
            y = hud_vert_pos + hud_extra_y},
            "hud_temp_normal.png" ),
        text = make_text_hud(player,
            {x = hud_body_temp_x,
            y = hud_vert_pos + hud_text_y} )
    }

    hud_data.enviro_temp = {
        image = make_image_hud(player,
            {x = hud_air_temp_x, y = hud_vert_pos},
            "hud_air_temp.png" ),
        flare = make_image_hud(player,
            {x = hud_air_temp_x,
            y = hud_vert_pos + hud_extra_y},
            "hud_temp_normal.png" ),
        text = make_text_hud(player,
            {x = hud_air_temp_x,
            y = hud_vert_pos + hud_text_y} )
    }

    hud_data.effects = {
        image = make_image_hud(player,
            {x = hud_sick_x + longbarpos[lb].x,
            y = hud_vert_pos + longbarpos[lb].y},
            "hud_effects.png" ),
        text = make_text_hud(player,
            {x = hud_sick_x + longbarpos[lb].x,
            y = hud_vert_pos + hud_text_y + longbarpos[lb].y} )
    }
end

minetest.register_on_joinplayer(function(player) setup_hud(player) end)

-- status indicator colors for use in stat display option

local function color(v)
    local stat_col = stat_color.fine
    if v <= 20 then
        stat_col = stat_color.extreme
    elseif v <= 40 then
        stat_col = stat_color.major
    elseif v <= 60 then
        stat_col = stat_color.problem
    elseif v <= 80 then
        stat_col = stat_color.slight
    end
    return stat_col
end

local function color_bodytemp(v)
    local stat_col = stat_color.fine
    local ttype = "hud_temp_normal"
    if v > 47 or v < 27 then
        stat_col = stat_color.extreme
        if v > 47 then ttype = "hud_temp_hot" end
        if v < 27 then ttype = "hud_temp_cold" end
    elseif v > 43 or v < 32 then
        stat_col = stat_color.major
        if v > 43 then ttype = "hud_temp_hot" end
        if v < 32 then ttype = "hud_temp_cold" end
    elseif v > 38 or v < 37 then
        stat_col = stat_color.problem
        if v > 38 then ttype = "hud_temp_hot" end
        if v < 37 then ttype = "hud_temp_cold" end
    end
    return stat_col, ttype
end

local function color_envirotemp(v, meta)
    --make sure matches actual values used!
    local comfort_low = meta:get_int("clothing_temp_min")
    local comfort_high = meta:get_int("clothing_temp_max")
    local stress_low = comfort_low - 10
    local stress_high = comfort_high + 10
    local danger_low = stress_low - 40
    local danger_high = stress_high +40
    local overlay

    local stat_col = stat_color.fine
    local ttype = "hud_temp_normal"

    if v > danger_high or v < danger_low then
        stat_col = stat_color.extreme
        if v > danger_high then ttype = "hud_temp_hot" end
        if v < danger_low then ttype = "hud_temp_cold" end
    elseif v > stress_high or v < stress_low then
        stat_col = stat_color.major
        if v > stress_high then ttype = "hud_temp_hot" end
        if v < stress_low then ttype = "hud_temp_cold" end
    elseif v > comfort_high or v < comfort_low then
        stat_col = stat_color.slight
        if v > comfort_high then ttype = "hud_temp_hot" end
        if v < comfort_low then ttype = "hud_temp_cold" end
    end
    if v < stress_low then
        overlay = "weather_hud_frost.png"
    end
    if v > stress_high then
        overlay = "weather_hud_heat.png"
    end

    return stat_col, ttype, overlay
end

-- player, hud_data, health type (e.g. health or hunger), color, opacity, text value
-- will do blink for you
local function health_hud_change(player, hud_data, htype, color, textval)
    local data = hud_data[htype]
    if not (data and data.image and data.text) then return end
    -- get opacity (hidden means opacity of 0)
    local opac = data.hidden and 0 or hud_data.opacity or mthudopacity
    opac = type(opac) == "number" and opac or tonumber(opac) or 127
    -- get blink of temp if body_temp, otherwise assume htype
    local image = concat_text("hud_",htype,".png^[colorize:#",color,
      "^[opacity:",opac,blink(hud_data.blink[htype]) )
    player:hud_change(data.image, "text", image) -- update icon
    -- tonumber opac for comparison
    opac = type(opac) == "number" and opac or tonumber(opac)
    -- update numbered percentages if text is not hidden and stats visible
    local texthidden = data.hidden
    if not texthidden and are_stats_visible(hud_data) then
        player:hud_change(data.text, "number", tonumber(concat_text("0x", color)) )
        player:hud_change(data.text, "text", textval)
    -- otherwise hide
    else
        player:hud_change(data.text, "text", "")
    end
end

local function do_overlay(player, pname, pos, overlay)
    local handle = player:hud_add({
            name = overlay,
            [hud_type] = "image",
            position = {x = 0.5, y = 0.5},
            alignment = {x = 0, y = 0},
            scale = { x = -100, y = -100},
            z_index = hud.z_index,
            text = overlay,
            offset = {x = 0, y = 0}
    })
    hud[pname].overlay = handle
end

local stat_funcs = {
    health = function(player, hud_data)
        -- get value percentage
        local v = player:get_hp()
        v = (v/20)*100
        local stat_col = color(v)
        local t = concat_text(v, " %")
        -- update health hud
        health_hud_change(player, hud_data, "health", stat_col, t)
    end,
    energy = function(player, hud_data, meta)
        -- get value percentage
        local v = meta:get_int("energy")
        v = v/10 -- we can already derive a percentage (1000/10)
        local stat_col = color(v)
        local t = concat_text(v, " %")
        -- update energy hud
        health_hud_change(player, hud_data, "energy", stat_col, t)
    end,
    thirst = function(player, hud_data, meta)
        -- get value percentage
        local v = meta:get_int("thirst") -- (we're already a percentage, 100 out of 100)
        local t = concat_text(v, " %")
        local stat_col = color(v)
        -- update thirst hud
        health_hud_change(player, hud_data, "thirst", stat_col, t)
    end,
    hunger = function(player, hud_data, meta)
        -- get value percentage
        local v = meta:get_int("hunger")
        v = v/10 -- we can already derive a percentage (1000/10)
        local t = concat_text(v, " %")
        local stat_col = color(v)
        -- update hunger hud
        health_hud_change(player, hud_data, "hunger", stat_col, t)
    end,
    body_temp = function(player, hud_data, meta)
        -- get data
        local data = hud_data.body_temp
        if not (data and data.image and data.flare and data.text) then return end
        -- get value
        local v = meta:get_int("temperature")
        local stat_col, ttype = color_bodytemp(v)
        local t = climate.get_temp_string(v, meta)
        -- get opacity (hidden means opacity of 0)
        local opac = data.hidden and 0 or hud_data.opacity or mthudopacity
        opac = type(opac) == "number" and opac or tonumber(opac) or 127
        -- update hud
        player:hud_change(data.image, "text", concat_text("hud_body_temp.png^[colorize:#", stat_col,
          "^[opacity:", opac, blink(hud_data.blink["temp"]) ) )
        -- only update text if text isn't hidden and stats are visible
        local hudtext = data.text
        local hidden = data.hidden
        if not hidden and are_stats_visible(hud_data) then
            local hudtype = hud_data.p_body_temp_type
            -- don't colorize (cold/hot icon above icon)
            player:hud_change(data.flare, "text", concat_text(ttype, ".png^[opacity:", opac) )
            player:hud_change(hudtext, "number", tonumber(concat_text("0x", stat_col)) ) -- colorize
            player:hud_change(hudtext, "text", t)
        else
            player:hud_change(hudtext, "text", "")
        end
    end,
    enviro_temp = function(player, hud_data, meta)
        -- get data
        local data = hud_data.enviro_temp
        if not (data and data.image and data.flare and data.text) then return end
        -- get position and check temp
        local pname = player:get_player_name()
        local player_pos = player:get_pos()
        player_pos.y = player_pos.y + 0.6 --adjust to body height
        local v = math.floor(climate.get_point_temp(player_pos, true))
        if data.prev_v == v then return end -- don't update hud if we're the same value
        data.prev_v = v -- add to prev
        -- get meta and temperature reading
        meta = type(meta) == "userdata" and meta or player:get_meta()
        local stat_col, ttype, overlay = color_envirotemp(v, meta)
        if overlay then
            if not hud_data.overlay then
                do_overlay(player, pname, player_pos, overlay)
            elseif player:hud_get(hud_data.overlay) and
                ( overlay ~= player:hud_get(hud_data.overlay).name ) then
                -- direct transition from one overlay to another
                player:hud_remove(hud_data.overlay)
                do_overlay(player, pname, player_pos, overlay)
            end
        elseif hud_data.overlay then -- remove overlay
            player:hud_remove(hud_data.overlay)
            hud_data.overlay = nil
        end
        local t = climate.get_temp_string(v, meta)
        -- get opacity (hidden means opacity of 0)
        local opac = data.hidden and 0 or hud_data.opacity or mthudopacity
        opac = type(opac) == "number" and opac or tonumber(opac) or 127
        player:hud_change(data.image, "text", concat_text("hud_air_temp.png^[colorize:#",stat_col,
          "^[opacity:",opac, blink(hud_data.blink["enviro_temp"]) ) )
        -- don't colorize (cold/hot icon above icon)
        player:hud_change(data.flare, "text", concat_text(ttype, ".png^[opacity:",opac) )
        -- only update text if not hidden and stats are visible
        if not data.hidden and are_stats_visible(hud_data) then
            player:hud_change(data.text, "number", tonumber(concat_text("0x",stat_col)) )
            player:hud_change(data.text, "text", t)
        else
            player:hud_change(data.text, "text", "")
        end
    end,
    effects = function(player, hud_data, meta)
        -- calculate stat color
        local stat_col = stat_color.fine
        local v = meta:get_int("effects_num")
        local t = concat_text("x", v)
        if v > 4 then
            stat_col = stat_color.extreme
        elseif v > 2 then
            stat_col = stat_color.major
        elseif v > 1 then
            stat_col = stat_color.problem
        elseif v > 0 then
            stat_col = stat_color.slight
        end
        -- update effects hud
        health_hud_change(player, hud_data, "effects", stat_col, t)
  end,
}

-- update placement of hud icons when hud16 (longbar) is modified
-- value will be false or true
minimal.register_on_player_setting_change(function(player, setting, value, meta)
    local hud_data = hud[player:get_player_name()]
    if not hud_data then return end
    if setting == "hud16" and (hud_data.health and hud_data.effects) then
        player:hud_change(hud_data.health.image, "offset",
                          {x = hud_health_x - longbarpos[value].x,
                           y = hud_vert_pos + longbarpos[value].y})
        player:hud_change(hud_data.health.text, "offset",
                          {x = hud_health_x - longbarpos[value].x,
                           y = hud_vert_pos + hud_text_y + longbarpos[value].y})
        player:hud_change(hud_data.effects.image, "offset",
                          {x = hud_body_temp_x + longbarpos[value].x,
                           y = hud_vert_pos + longbarpos[value].y})
        player:hud_change(hud_data.effects.text, "offset",
                          {x = hud_body_temp_x + longbarpos[value].x,
                           y = hud_vert_pos + hud_text_y + longbarpos[value].y})
    -- modifying opacity
    elseif setting == "hud_opacity" then
        -- iterate over each hud
        for nm,data in pairs(hud_data) do
            -- if we have a function for it, call it!
            if stat_funcs[nm] then
                stat_funcs[nm](player, hud_data, meta)
            end
        end
    end
end)

-- only change hud when stats have been modified
HEALTH.register_on_stat_change(function(player, setting, value, meta)
    -- player's "temperature" will be "body_temp"
    setting = setting == "temperature" and "body_temp" or setting
    local stat_func = stat_funcs[setting]
    -- not found
    if not stat_func then return end
    local hud_data = hud[player:get_player_name()]
    if not hud_data then return end -- no hud_data oops
    stat_func(player, hud_data, meta)
end)


local timer = 0
local blinktimer = 0

minetest.register_globalstep(function(dtime)
        timer = timer + dtime
        blinktimer = blinktimer + dtime
        if blinktimer > 0.5 then blinktimer = 0 ; blinkingnow = not blinkingnow end
        if timer > hudupdateseconds then
            for _0, player in ipairs(minetest.get_connected_players()) do

                local name = player:get_player_name()
                local hud_data = hud[name]
                if not hud_data then
                    return
                end
                -- update health and enviro_temp
                stat_funcs["health"](player, hud_data)
                stat_funcs["enviro_temp"](player, hud_data)
                local wi = player:get_wielded_item():get_name()
                if hud_data.wh ~= wi then -- changed, remove it
                    if wielded_hud.list[hud_data.wh] then
                        wielded_hud.list[hud_data.wh].unwield(player, name)
                    end
                    hud_data.wh = nil
                end
                if wielded_hud.list[wi] then
                    hud_data.wh = wi
                    wielded_hud.list[wi].update(player, name)
                end
            end
            timer = 0
            return nil
        end
end)
