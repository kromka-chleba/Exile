----------------------------------------------------------------------
--HUD
----------------------------------------------------------------------

-- Internationalization
HEALTH = HEALTH
local S = HEALTH.S

local hud = {}
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

local stat_fine         = "FFFFFF"
local stat_slight       = "FDFF46"
local stat_problem      = "FF8100"
local stat_major        = "DF0000"
local stat_extreme      = "8008FF"

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

local typelist = { "health", "energy", "thirst", "hunger",
                   "temp", "enviro_temp", "effects" }
function HEALTH.hide_hud_elements(player, meta, list, hide)
    -- Takes a string of elements to hide, or "all", sets them hidden
    -- Needs either player or meta to apply changes to
    -- hide, if true, inverts this function to show elements
    if not meta and not player then
        error("Tried to hide hud elements for non-existent player and meta!")
    end
    if not meta then meta = player:get_meta() end
    local hidetable = {}
    for i = 1, #typelist do
        if string.match(list, typelist[i]) or string == "all" then
            hidetable[typelist[i]] = ( true ~= hide)
        end
    end
    meta:set_string("hidehud", minetest.serialize(hidetable))
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

    hud_data.p_health = make_image_hud(player,
                                       {x = hud_health_x - longbarpos[lb].x,
                                        y = hud_vert_pos + longbarpos[lb].y},
                                       "hud_health.png" )

    hud_data.p_hunger = make_image_hud(player,
                                       {x = hud_hunger_x, y = hud_vert_pos},
                                       "hud_hunger.png" )

    hud_data.p_thirst = make_image_hud(player,
                                       {x = hud_thirst_x, y = hud_vert_pos},
                                       "hud_thirst.png" )

    hud_data.p_energy = make_image_hud(player,
                                       {x = hud_energy_x, y = hud_vert_pos},
                                       "hud_energy.png" )

    hud_data.p_body_temp = make_image_hud(player,
                                          {x = hud_body_temp_x, y = hud_vert_pos},
                                          "hud_body_temp.png" )

    hud_data.p_body_temp_type = make_image_hud(player,
                                               {x = hud_body_temp_x,
                                                y = hud_vert_pos + hud_extra_y},
                                               "hud_temp_normal.png" )

    hud_data.p_air_temp = make_image_hud(player,
                                         {x = hud_air_temp_x, y = hud_vert_pos},
                                         "hud_air_temp.png" )

    hud_data.p_air_temp_type = make_image_hud(player,
                                              {x = hud_air_temp_x,
                                               y = hud_vert_pos + hud_extra_y},
                                              "hud_temp_normal.png" )

    hud_data.p_sick = make_image_hud(player,
                                     {x = hud_sick_x + longbarpos[lb].x,
                                      y = hud_vert_pos + longbarpos[lb].y},
                                     "hud_sick.png" )

    hud_data.p_health_text = make_text_hud(
        player,
        {x = hud_health_x + longbarpos[lb].x,
         y = hud_vert_pos + hud_text_y + longbarpos[lb].y} )

    hud_data.p_hunger_text = make_text_hud(player,
                                           {x = hud_hunger_x,
                                            y = hud_vert_pos + hud_text_y} )

    hud_data.p_thirst_text = make_text_hud(player,
                                           {x = hud_thirst_x,
                                            y = hud_vert_pos + hud_text_y} )

    hud_data.p_energy_text = make_text_hud(player,
                                           {x = hud_energy_x,
                                            y = hud_vert_pos + hud_text_y} )

    hud_data.p_body_temp_text = make_text_hud(player,
                                              {x = hud_body_temp_x,
                                               y = hud_vert_pos + hud_text_y} )

    hud_data.p_air_temp_text = make_text_hud(player,
                                             {x = hud_air_temp_x,
                                              y = hud_vert_pos + hud_text_y} )

    hud_data.p_sick_text = make_text_hud(
        player,
        {x = hud_sick_x,
         y = hud_vert_pos + hud_text_y + longbarpos[lb].y} )

end

minetest.register_on_joinplayer(function(player) setup_hud(player) end)

-- status indicator colors for use in stat display option

local function color(v)
    local stat_col = stat_fine
    if v <= 20 then
        stat_col = stat_extreme
    elseif v <= 40 then
        stat_col = stat_major
    elseif v <= 60 then
        stat_col = stat_problem
    elseif v <= 80 then
        stat_col = stat_slight
    end
    return stat_col
end

local function color_bodytemp(v)
    local stat_col = stat_fine
    local ttype = "hud_temp_normal"
    if v > 47 or v < 27 then
        stat_col = stat_extreme
        if v > 47 then ttype = "hud_temp_hot" end
        if v < 27 then ttype = "hud_temp_cold" end
    elseif v > 43 or v < 32 then
        stat_col = stat_major
        if v > 43 then ttype = "hud_temp_hot" end
        if v < 32 then ttype = "hud_temp_cold" end
    elseif v > 38 or v < 37 then
        stat_col = stat_problem
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

    local stat_col = stat_fine
    local ttype = "hud_temp_normal"

    if v > danger_high or v < danger_low then
        stat_col = stat_extreme
        if v > danger_high then ttype = "hud_temp_hot" end
        if v < danger_low then ttype = "hud_temp_cold" end
    elseif v > stress_high or v < stress_low then
        stat_col = stat_major
        if v > stress_high then ttype = "hud_temp_hot" end
        if v < stress_low then ttype = "hud_temp_cold" end
    elseif v > comfort_high or v < comfort_low then
        stat_col = stat_slight
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

local function health(player, hud_data, hidden)
    local v = player:get_hp()
    v = (v/20)*100
    local stat_col = color(v)
    local t = v .." %"
    local hud1 = hud_data.p_health
    local opac = hud_data.opacity or mthudopacity
    if hidden then opac = 0 end
    player:hud_change(hud1, "text", "hud_health.png^[colorize:#"..
                      stat_col.."^[opacity:"..opac..
                      blink(hud_data.blink["health"]))

    local hud2 = hud_data.p_health_text
    player:hud_change(hud2, "number", tonumber("0x"..stat_col))
    if not hidden and are_stats_visible(hud_data) then
        player:hud_change(hud2, "text", t)
    else
        player:hud_change(hud2, "text", "")
    end
end

local function energy(player, hud_data, meta, hidden)
    local v = meta:get_int("energy")
    v = (v/1000)*100
    local stat_col = color(v)
    local t = v .." %"
    local hud1 = hud_data.p_energy
    local opac = hud_data.opacity or mthudopacity
    if hidden then opac = 0 end
    player:hud_change(hud1, "text", "hud_energy.png^[colorize:#"..
                      stat_col.."^[opacity:"..opac..
                      blink(hud_data.blink["energy"]))
    local hud2 = hud_data.p_energy_text
    player:hud_change(hud2, "number", tonumber("0x"..stat_col))

    if not hidden and are_stats_visible(hud_data) then
        player:hud_change(hud2, "text", t)
    else
        player:hud_change(hud2, "text", "")
    end
end

local function thirst(player, hud_data, meta, hidden)
    local v = meta:get_int("thirst")
    v = (v/100)*100
    local t = v .." %"
    local stat_col = color(v)
    local hud1 =  hud_data.p_thirst
    local opac = hud_data.opacity or mthudopacity
    if hidden then opac = 0 end
    player:hud_change(hud1, "text", "hud_thirst.png^[colorize:#"..
                      stat_col.."^[opacity:"..opac..
                      blink(hud_data.blink["thirst"]))
    local hud2 = hud_data.p_thirst_text
    player:hud_change(hud2, "number", tonumber("0x"..stat_col))
    if not hidden and are_stats_visible(hud_data) then
        player:hud_change(hud2, "text", t)
    else
        player:hud_change(hud2, "text", "")
    end
end

local function hunger(player, hud_data, meta, hidden)
    local v = meta:get_int("hunger")
    v = (v/1000)*100
    local t = v .." %"
    local stat_col = color(v)
    local hud1 =  hud_data.p_hunger
    local opac = hud_data.opacity or mthudopacity
    if hidden then opac = 0 end
    player:hud_change(hud1, "text", "hud_hunger.png^[colorize:#"..
                      stat_col.."^[opacity:"..opac..
                      blink(hud_data.blink["hunger"]))
    local hud2 = hud_data.p_hunger_text
    player:hud_change(hud2, "number", tonumber("0x"..stat_col))
    if not hidden and are_stats_visible(hud_data) then
        player:hud_change(hud2, "text", t)
    else
        player:hud_change(hud2, "text", "")
    end
end

local function temp(player, hud_data, meta, hidden)
    local v = meta:get_int("temperature")
    local stat_col, ttype = color_bodytemp(v)
    local t = climate.get_temp_string(v, meta)
    local hud1 = hud_data.p_body_temp
    local opac = hud_data.opacity or mthudopacity
    if hidden then opac = 0 end
    player:hud_change(hud1, "text", "hud_body_temp.png^[colorize:#"..
                      stat_col.."^[opacity:"..opac..
                      blink(hud_data.blink["temp"]))
    local hudtype = hud_data.p_body_temp_type
    local hudtext = hud_data.p_body_temp_text
    player:hud_change(hudtype, "text", ttype..
                      ".png^[opacity:"..opac) -- don't colorize
    player:hud_change(hudtext, "number", tonumber("0x"..stat_col))
    if not hidden and are_stats_visible(hud_data) then
        player:hud_change(hudtext, "text", t)
    else
        player:hud_change(hudtext, "text", "")
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

local function enviro_temp(player, hud_data, meta, hidden)
    local pname = player:get_player_name()
    local player_pos = player:get_pos()
    player_pos.y = player_pos.y + 0.6 --adjust to body height
    local v = math.floor(climate.get_point_temp(player_pos, true))
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
    local newhud = hud_data.p_air_temp
    local newhud2 = hud_data.p_air_temp_type
    local opac = hud_data.opacity or mthudopacity
    if hidden then opac = 0 end
    player:hud_change(newhud, "text", "hud_air_temp.png^[colorize:#"..
                      stat_col.."^[opacity:"..opac..
                      blink(hud_data.blink["enviro_temp"]))
    player:hud_change(newhud2, "text", ttype..
                      ".png^[opacity:"..opac) -- don't colorize)
    local hud2 = hud_data.p_air_temp_text
    player:hud_change(hud2, "number", tonumber("0x"..stat_col))
    if not hidden and are_stats_visible(hud_data) then
        player:hud_change(hud2, "text", t)
    else
        player:hud_change(hud2, "text", "")
    end
end

local function effects(player, hud_data, meta, hidden)
    local stat_col = stat_fine
    local v = meta:get_int("effects_num")
    local t = "x"..v
    if v > 0 then
        stat_col = stat_slight
    elseif v > 1 then
        stat_col = stat_problem
    elseif v > 2 then
        stat_col = stat_major
    elseif v > 3 then
        stat_col = stat_extreme
    end
    local hud1 = hud_data.p_sick
    local opac = hud_data.opacity or mthudopacity
    if hidden then opac = 0 end
    player:hud_change(hud1, "text", "hud_sick.png^[colorize:#"..
                      stat_col.."^[opacity:"..opac..
                      blink(hud_data.blink["effects"]))
    local hud2 = hud_data.p_sick_text
    player:hud_change(hud2, "number", tonumber("0x"..stat_col))
    if not hidden and are_stats_visible(hud_data) then
        player:hud_change(hud2, "text", t)
    else
        player:hud_change(hud2, "text", "")
    end
end

local timer = 0
local blinktimer = 0

minetest.register_globalstep(function(dtime)
        timer = timer + dtime
        blinktimer = blinktimer + dtime
        if blinktimer > 0.5 then blinktimer = 0 ; blinkingnow = not blinkingnow end
        if timer > hudupdateseconds then
            for _0, player in ipairs(minetest.get_connected_players()) do

                local name = player:get_player_name()
                local meta = player:get_meta()
                local hud_data = hud[name]
                if not hud_data then
                    return
                end

                local hidehud =  minetest.deserialize(meta:get_string("hidehud"))
                    or {}
                health(player, hud_data, hidehud.health)
                energy(player, hud_data, meta, hidehud.energy)
                thirst(player, hud_data, meta, hidehud.thirst)
                hunger(player, hud_data, meta, hidehud.hunger)
                temp(player, hud_data, meta, hidehud.temp)
                enviro_temp(player, hud_data, meta, hidehud.enviro_temp)
                effects(player, hud_data, meta, hidehud.effects)
                local wi = player:get_wielded_item():get_name()
                if hud_data.wh ~= wi then -- changed, remove it
                    if wielded_hud.list[hud_data.wh] then
                        wielded_hud.list[hud_data.wh].unwield(player, name, meta)
                    end
                    hud_data.wh = nil
                end
                if wielded_hud.list[wi] then
                    hud_data.wh = wi
                    wielded_hud.list[wi].update(player, name, meta)
                end

                local lb = tobool(meta:get_string("hud16"))

                player:hud_change(hud_data.p_health, "offset",
                                  {x = hud_health_x - longbarpos[lb].x,
                                   y = hud_vert_pos + longbarpos[lb].y})
                player:hud_change(hud_data.p_health_text, "offset",
                                  {x = hud_health_x - longbarpos[lb].x,
                                   y = hud_vert_pos + hud_text_y + longbarpos[lb].y})
                player:hud_change(hud_data.p_sick, "offset",
                                  {x = hud_body_temp_x + longbarpos[lb].x,
                                   y = hud_vert_pos + longbarpos[lb].y})
                player:hud_change(hud_data.p_sick_text, "offset",
                                  {x = hud_body_temp_x + longbarpos[lb].x,
                                   y = hud_vert_pos + hud_text_y + longbarpos[lb].y})
            end
            timer = 0
            return nil
        end
end)
