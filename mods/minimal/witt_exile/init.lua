-- Zoom WITT
local witt = dofile(minetest.get_modpath('minimal').."/witt_exile/help.lua")

local shown = {}

minetest.register_on_joinplayer(function(player)
        player:set_properties({zoom_fov = 72})
end)

local function unshow(player)
    witt.unshow(player)
    shown[player] = nil
end

local function show(player)
    local returnliquid = false
    local def = player:get_wielded_item():get_definition()
    if def and def.liquids_pointable == true then returnliquid = true end
    local ptd = minimal.get_pointed_thing(player, nil, true, returnliquid)
    if not ptd then return end
    if ptd.type == "object" then
        local obj = ptd.ref:get_luaentity().name
        local ndesc = minetest.registered_entities[obj]._desc
        if ndesc then
            witt.show(player, "",
                      ndesc, obj, "entity")
            shown[player] = obj
            return
        end
    end

    if ( ptd.type ~= "node" ) then return end

    local nname = minetest.get_node(ptd.under)
    nname = ( nname and nname.name )

    if not nname then return end
    if shown[player] == nname then return end

    local form_view, item_type, node_definition
        = witt.get_node_tiles(nname)

    if not node_definition then return end

    local node_description = node_definition.description
    local mod_name, _ = witt.split_item_name(nname)

    witt.show(player, form_view, node_description, nname,
              item_type, mod_name)
    shown[player] = nname
end

local time = 0
minetest.register_globalstep(function(dtime)
        time = time + dtime
        if time < 0.1 then return end
        time = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            local ctl = player:get_player_control()
            if ctl.zoom then
                show(player)
            elseif not ctl.zoom and shown[player] then
                unshow(player)
            end
        end
end)
