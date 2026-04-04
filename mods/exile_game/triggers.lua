
--namespace
triggers = {}
triggers.player = {} -- for timeouts on effects

local hud_type = EXILE.hud_type


local S = core.get_translator("exile_game")

-- Functions: ------------------------------------------------------------

local usedlist = {} -- temporarily remember who has activated each trigger

local function used_before(nmeta, pname)
    -- Allows a trigger to be used by a player just once per server start
    -- #TODO: is it worth saving this to prevent stop/start to reuse triggers?
    local label = nmeta:get_string("tr_label")
    if label == "" then return false end
    if usedlist[label] == nil then
        usedlist[label] = {} -- this trigger hasn't been used by <player> yet
        usedlist[label][pname] = true
        return false
    end
    if usedlist[label][pname] == true then
        return true
    end
end

function triggers.clear_used_triggers(name)
    for label in pairs(usedlist) do
        usedlist[label][name] = nil
    end
end


-- Triggers: -------------------------------------------------------------

local health
local l_climate
local l_player_api
-- needed for quick_physics until a full player state api is written
minetest.register_on_mods_loaded(function()
    health = HEALTH
    l_climate = climate
    l_player_api = player_api
end)

local function reset_player(player, pname, pos, nmeta, metastring)
    local pmeta = player:get_meta()
    player:set_hp(20)
    health.set_int(player, pmeta, "energy", 1000)
    health.set_int(player, pmeta, "hunger", 1000)
    health.set_int(player, pmeta, "thirst", 100)
    health.quick_physics(player, pmeta)
    return true
end

local function hurt_player(player, pname, pos, nmeta, metastring)
    local damage = tonumber(metastring) or 2
    player:punch(player, 1.0, {full_punch_interval = 1.0,
                               damage_groups = {fleshy=damage} }, nil)
    return true
end

local function sethealth(player, pname, pos, nmeta, metastring)
    local val = tonumber(metastring) or 20
    player:set_hp(val)
    health.quick_physics(player, nmeta)
    return true
end

local function setenergy(player, pname, pos, nmeta, metastring)
    local val = tonumber(metastring)
    if not val then return end
    local pmeta = player:get_meta()
    health.set_int(player, pmeta, "energy", val * 10) -- energy is 1-1000, tenths of percent
    health.quick_physics(player, pmeta)
    return true
end
local function sethunger(player, pname, pos, nmeta, metastring)
    local val = tonumber(metastring)
    if not val then return end
    local pmeta = player:get_meta()
    health.set_int(player, pmeta, "hunger", val * 10) -- 1-1000, same as energy
    health.quick_physics(player, pmeta)
    return true
end
local function setthirst(player, pname, pos, nmeta, metastring)
    local val = tonumber(metastring)
    if not val then return end
    local pmeta = player:get_meta()
    health.set_int(player, pmeta, "thirst", val) -- thirst is 1-100
    health.quick_physics(player, pmeta)
    return true
end

local function teleport(player, pname, pos, nmeta, metastring)
    local vec = vector.from_string(metastring)
    if not vec then
        minetest.chat_send_player(pname, S("Invalid teleport vector, "..
                                           "must be '(x,y,z)'"))
        return
    end
    player:set_pos(vec)
end

local function relaport(player, pname, pos, nmeta, metastring)
    local vec = vector.from_string(metastring)
    if not vec then
        minetest.chat_send_player(pname, S("Invalid teleport vector, "..
                                           "must be '(x,y,z)'"))
        return
    end
    player:set_pos(vector.add(pos, vec))
end

local function clearinv(player, pname, pos, nmeta, metastring)
    metastring = "main"
    --[[
        if metastring ~= "main" and metastring ~= "cloths"
        and metastring ~="both" then
        -- #TODO: clearing clothing doesn't update player appearance, fix it
        return
        end ]]--
    local inv = player:get_inventory()
    if metastring == "main" or metastring == "both"  then
        inv:set_list("main", {})
        l_player_api.add_player_hand(player)
    end
    if metastring == "cloths" or metastring == "both"  then
        inv:set_list("cloths", {})
        l_player_api.compose_cloth(player)
    end
end

local function setinventory(player, pname, pos, nmeta, metastring)
    metastring = "main" -- until we can set clothing inv too
    local plinv = player:get_inventory()
    local triginv = nmeta:get_inventory():get_list(metastring)
    plinv:set_list(metastring, triginv)
end
local function giveitem(player, pname, pos, nmeta, metastring)
    if used_before(nmeta, pname) then
        return -- You'll have to try harder for freebies, Jack
    end
    local stack = ItemStack(metastring)
    local inv = player:get_inventory()
    if inv:room_for_item("main", stack) then
        inv:add_item("main", stack)
    else -- no room for items? happy birthday to the ground!
        minetest.item_drop(stack, player, pos)
    end
end

local function setweather(player, pname, pos, nmeta, metastring)
    l_climate.set_weather_override(pname, player, metastring)
end

local function resetweather(player, pname, pos, nmeta, metastring)
    l_climate.set_weather_override(pname, player, "")
end

local function hide_hud(player, pname, pos, nmeta, metastring)
    health.hide_hud_elements(player, nil, metastring)
end

local function showall_hud(player, pname, pos, nmeta, metastring)
    health.show_hud_elements(player, nil, "all")
end


local splash = {}
-- Show an icon and line of text on the center of the player's screen
function triggers.hud_splash(player, icon_name, text_line, pname)
    if not pname then pname = player:get_player_name() end
    local function clear_splash()
        local spl = splash[pname] or {}
        if spl.icon then player:hud_remove(spl.icon) end
        if spl.text then player:hud_remove(spl.text) end
        splash[pname] = nil
    end

    if splash[pname] then
        splash[pname].job:cancel()
        clear_splash()
    end
    local icon = icon_name
    local text = text_line
    local item = {}
    if icon then
        item.icon = player:hud_add({
                [hud_type] = "image",
                name = "splash_icon",
                text = icon,
                scale = { x = 2, y = 2 },
                position = { x = 0.5, y = 0.45 },
        })
    end
    if text then
        item.text = player:hud_add({
                [hud_type] = "text",
                name = "splash_text",
                text = text,
                number = "0xFFFFFF",
                size = { x = 2 },
                position = { x = 0.5, y = 0.54 },
        })
    end
    splash[pname] = item
    splash[pname].job = minetest.after(2.5, function()
                                           clear_splash()
    end)
end

-- private call that handles translation from metastring
local function hud_splash(player, pname, pos, nmeta, metastring)
    if used_before(nmeta, pname) then
        return
    end
    local icon = string.split(metastring, ",")[1]
    local text = string.split(metastring, ",")[2]
    triggers.hud_splash(player, icon, text, pname)
end

triggers.defs = {
    ["tr_reset"] = reset_player,
    ["tr_hurt"] = hurt_player,
    ["tr_energy"] = setenergy,
    ["tr_hp"] = sethealth,
    ["tr_hunger"] = sethunger,
    ["tr_thirst"] = setthirst,
    ["tr_teleport"] = teleport,
    ["tr_relaport"] = relaport,
    ["tr_clearinv"] = clearinv,
    ["tr_setinv"] = setinventory,
    ["tr_giveitem"] = giveitem,
    ["tr_setweather"] = setweather,
    ["tr_resetweather"] = resetweather,
    ["tr_hudhide"] = hide_hud,
    ["tr_hudshow"] = showall_hud,
    ["tr_hudsplash"] = hud_splash,
}

local info = {
    ["tr_reset"] = { S("Reset player"),
                     S("Will reset player stats to full")},
    ["tr_hurt"]  = { S("Hurt player"), S("Hits player for <value> damage, 1-20")},
    ["tr_energy"]= { S("Set energy"), S("Set player energy to <value> percent")},
    ["tr_hp"]    = { S("Set HP"), S("Set player hp to <value>, 0-20")},
    ["tr_hunger"]= { S("Set hunger"), S("Set player hunger to <value> percent")},
    ["tr_thirst"]= { S("Set thirst"), S("Set player thirst to <value> percent")},
    ["tr_teleport"]={S("Teleport"), S("Send player to an exact xyz position")..
                         ", ( 125, 9003, -57 )" },
    ["tr_relaport"]={S("Relaport"), S("Send player a relative xyz distance")..
                         ", ( 1, 10, -5 )" },
    ["tr_clearinv"]={S("Clear inventory"), S("Empties main inventory")},
    ["tr_setinv"]  ={S("Set inventory"),
                     S("Overwrite player inv with contents")},
    ["tr_giveitem"]={S("Give item"), S("Gives an item, in itemstring format")..
                         S("This requires a unique label.")},
    ["tr_setweather"]={S("Set weather"), S("Changes weather displayed to player")
                           .."\n"..
                           S("Use /set_weather help to list available weather.")},
    ["tr_resetweather"]={S("Reset weather"),
                         S("Restores normal weather for player")},
    ["tr_hudhide"]={S("Hide hud elements"),
                    S("Hide health/energy/thirst/hunger/temp/").."\n"..
                        S("/enviro_temp/effects by names, or all")},
    ["tr_hudshow"]={S("Show hud elements"),S("Restore all hidden hud elements")},
    ["tr_hudsplash"]={S("Show hud splash"),S("Display an image and text\n"..
                                             "<icon name.png>,<text>")},
}

-- table of triggers with no input field
local noinputfield = {
    ["tr_reset"] = true,
    ["tr_clearinv"] = true,
    ["tr_setinv"] = true,
    ["tr_resetweather"] = true,
    ["tr_hudshow"] = true
}
--Register a function to add as a trigger

-- for example:
--     local function mytriggerfunc(player, pname, pos, nmeta, metastring) end
--
--     triggers.register("tr_mytrigger", mytriggerfunc, false,
--                       {"My Trigger", "This does custom stuff"})

function triggers.register(name, trfunction, inputfield, infotable)
    triggers.defs[name] = trfunction
    info[name] = infotable
    if inputfield == true then
        noinputfield[name] = true
    end
end
function triggers.activate(pos, player, nodemeta)
    if not player or not minetest.is_player(player) then
        minetest.log("error", "Attempted to run a trigger at "..pos.x..
                     "/"..pos.y.."/"..pos.z..
                     "with no valid player!")
        return
    end
    pos = vector.round(pos)
    local posstr = vector.to_string(pos)
    local time = minetest.get_gametime()
    local pname = player:get_player_name()
    -- check if the player has already triggered this recently
    if triggers.player[pname] and triggers.player[pname][posstr] then
        if time - triggers.player[pname][posstr] < 2 then
            return
        else -- timer has expired
            triggers.player[pname][posstr] = nil
        end
    end
    if not nodemeta then
        nodemeta = minetest.get_meta(pos)
    end
    local updphys = false
    for nm, func in pairs(triggers.defs) do
        local val = nodemeta:get_string(nm)
        if val ~= "" then
            updphys = func(player, pname, pos, nodemeta, val)
        end
    end
    triggers.player[pname] = { [posstr] = time }
    if updphys then
        health.update_player_physics(player)
    end
end

-- Formspec --------------------------------------------------------------

local dropdownstring = ""
local index = {}
local rindex = {}
local idx = 1
local comma = ""
minetest.register_on_mods_loaded(function()
        local list = {} local count = 0
        for nm, _ in pairs(info) do
            count = count + 1
            list[count] = nm
        end
        table.sort(list)
        for i = 1, #list do
            local nm = list[i]
            local val = info[nm]
            dropdownstring = dropdownstring..comma..val[1]
            index[nm] = idx
            rindex[idx] = nm
            idx = idx + 1
            comma = ","
        end
end)

local function triggerpage(sel, value)
    local spec =
        "dropdown[0.6,0.6;5,0.8;Trigger;"..
        dropdownstring..";"..index[sel]..";true]"..
        "label[3.3,2;"..info[sel][2].."]"
    if not noinputfield[sel] then
        spec = spec.."textarea[3.3,3;3,1.5;input_value;" ..
            S("Value:") .. ";" .. value .. "]"
    else
        local bool
        if value == "" then
            bool = S("False")
        else
            bool = S("True")
        end
        spec = spec.."label[3.3,3;"..bool.."]"
    end
    spec = spec.."button[7.85,3.375;1.25,0.75;btn_set;" .. S("Set") .. "]" ..
        "button[9.25,3.375;1.25,0.75;btn_unset;" .. S("Unset") .. "]"
    if sel == "tr_setinv" then
        spec = spec.."list[context;main;0,4;8,4;]list[current_player;"..
            "main;0,8;8,4;]"
    end
    return spec
end

local function setformspec(pos)
    local nodemeta = minetest.get_meta(pos)
    local sel = nodemeta:get_string("tr_selected")
    local label = nodemeta:get_string("tr_label")
    if sel == "" then sel = "tr_reset" end
    local value = nodemeta:get_string(sel)
    local spec =  "formspec_version[6]size[10.5,11]"..triggerpage(sel, value)
    spec = spec.."field[3,8;6,0.5;tr_label;"..S("Label")..";"..label.."]"

    nodemeta:set_string("formspec", spec)
end

function recfields(pos, formname, fields, sender)
    local node = minetest.get_node(pos)
    local trtype = minetest.get_item_group(node.name, "trigger")
    if trtype == nil or trtype == 0 then return end
    local nmeta = minetest.get_meta(pos)
    local sel
    if fields.Trigger then
        sel = rindex[tonumber(fields.Trigger)]
        nmeta:set_string("tr_selected",sel)
    end
    if fields.btn_set then
        local new_value = "true"
        if fields.input_value then
            new_value = fields.input_value:trim()
        end
        nmeta:set_string("tr_label", fields.tr_label)
        nmeta:set_string(sel, new_value)
    end
    if fields.btn_unset then
        nmeta:set_string(sel, "")
    end
end

-- Nodes -----------------------------------------------------------------

minetest.register_node(
    "exile_game:trigger", {
        description = S("Exile trigger node"),
        tiles = {"climate_air.png"},
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
        move_resistance = 1,
        pointable = false,
        walkable = false,
        buildable_to = false,
        diggable = false,
        floodable = false,
        is_ground_content = false,
        groups = {temp_pass = 1, trigger = 1},
        use_texture_alpha = "blend",
})

if minetest.is_creative_enabled() then
    minetest.override_item(
        'exile_game:trigger', {
            drawtype = "glasslike",
            pointable = true,
            diggable = true,
            groups = {crumbly = 1, cracky = 3,
                      temp_pass = 1, trigger = 1},
            tiles = {
                "tech_paint_gp_x.png",
            },
            on_construct = function(pos)
                setformspec(pos)
            end,
            on_receive_fields = function(pos, formname, fields, sender)
                recfields(pos, formname, fields, sender)
                setformspec(pos)
            end,
            after_place_node = function(pos, placer, itemstack, pointed_thing, nmeta, imeta)
                nmeta = nmeta or core.get_meta(pos)
                imeta = imeta or itemstack:get_meta()
                nmeta:set_string("tr_label", imeta:get_string("tr_label"))
                for nm, _ in pairs(triggers.defs) do
                    local val = imeta:get_string(nm)
                    if val ~= "" then
                        nmeta:set_string(nm, val)
                    end
                end
                local minv = nmeta:get_inventory()
                minv:set_size("main", 8*2)
                local iinv = EXILE.string2invlists(
                    imeta:get_string("inventory"))
                if iinv ~= "" and iinv ~= nil then
                    minv:set_lists(iinv)
                end
                local infotext = imeta:get_string("description")
                if infotext ~= "" then
                    nmeta:set_string("infotext", infotext)
                end
                nmeta:set_string("tr_selected",imeta:get_string("tr_selected"))
                setformspec(pos)
            end,
            preserve_metadata = function(pos, oldnode, oldmeta, drops, imeta)
                imeta = imeta or drops[1]:get_meta()
                local desc = ""
                local pmcomma = ""
                for nm, _ in pairs(triggers.defs) do
                    local val = oldmeta[nm] or ""
                    if val ~= "" then
                        imeta:set_string(nm, val)
                        desc = desc..pmcomma..nm:gsub("tr_","")
                        pmcomma = ", "
                    end
                end
                local oinv = minetest.get_meta(pos):get_inventory()
                local list = oinv:get_lists()
                imeta:set_string("inventory",
                                      EXILE.invlists2string(list))
                local label = oldmeta["tr_label"]
                imeta:set_string("tr_label", label)
                local name = label or S("Configured trigger")
                if desc ~= "" then
                    imeta:set_string("description",
                                          name.."\n"..desc)
                end
                imeta:set_string("tr_selected", oldmeta["tr_selected"])
            end,
    })
end
