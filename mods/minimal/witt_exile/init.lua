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
    local def = player:get_wielded_item():get_definition()
    -- returnliquid as 4th parameter
    local ptd = minimal.get_pointed_thing(player, nil, true, def and def.liquids_pointable)
    if not ptd then return end
    if ptd.type == "object" then
        local luaent = ptd.ref:get_luaentity()
        local obj = luaent.name
        local extra = luaent.witt_extra or {}
        local ndesc = minetest.registered_entities[obj]._desc
        local icon = minetest.registered_items[obj]
        if icon then
            icon = icon.inventory_image and icon.inventory_image.."^[resize:16x16" or nil
        end
        if ndesc then
            witt.show(player, icon,
                      ndesc, obj, "entity", extra)
            shown[player] = obj
        end
        return
    end

    if ( ptd.type ~= "node" ) then return end

    local node = minetest.get_node(ptd.under)
    local nname = node.name

    if not nname then return end
    if shown[player] == nname then return end

    local form_view, item_type, node_definition
        = witt.get_node_tiles(nname)

    if not node_definition then return end

    local descriptions = { node_definition.description }
    local mod_name, _ = witt.split_item_name(nname)
    if node_definition.witt_extra then
        local we_string = core.get_meta(ptd.under):get_string("witt_extra")
        descriptions = { descriptions[1],
                         unpack(core.deserialize(we_string) or {}) }
    end

    witt.show(player, form_view, descriptions, nname,
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
