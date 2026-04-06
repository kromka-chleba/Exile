local c_alpha = EXILE.compat_alpha

grafitti = {
    _palettes = {}
}

local g = grafitti
local _palette = {
    width = 8,
    items = {}
}

local function init_def_values(def)
    def = def or {}
    def.pointable = def.pointable or false
    return def
end

-- #TODO a minimmal function could be made to get this direction thing ?
-- check if not alreayd in core.
-- lef_handed rotation from the +z direction
-- 0 is front, 1 is -90° counter-clock rotation, etc...
-- to be used with facedir.
-- mirror = `true` is to be used if under ceiling
local function get_horizontal_direction(player, mirror)
    local yaw = player:get_look_horizontal()
    if yaw >= 5.5 or yaw < 0.785 then -- about 7Pi/4 and Pi/4
        -- front
         return mirror and 2 or 0
    elseif yaw < 2.356 then -- about 3Pi/4
        -- left
        return 3
         -- return mirror and 1 or 3
    elseif yaw < 3.927 then -- about 5Pi/4
        -- behind
         return mirror and 0 or 2
    else
        -- right
        return 1
        -- return mirror and 3 or 1
    end
end

-- gives the correct facedir to put in param2
-- from the direction of the node we are attached to
local function get_facedir(pointed_thing, player)
    local dir = vector.direction(pointed_thing.above, pointed_thing.under)
    -- bottom
    if dir.y == -1 then
        -- 0 (y+ face) + horizontal rotation counter_clock from z+
        return get_horizontal_direction(player)
    -- ceiling
    elseif dir.y == 1 then
        -- 20 (y- face) + horizontal rotation from z+ with mirror effect
        return 20 + get_horizontal_direction(player, true)
    -- sides
    elseif dir.x == 1 then -- need to have top facing x-
        -- 16 (x- face) + 3 (rotation to the right)
        return 17
    elseif dir.x == -1 then -- need to have top facing x+
        -- 12 (x+ face) + 1 (rotation to the left)
        return 15
    elseif dir.z == 1 then -- need to have top facing z-
        -- 8 (z- face)
        return 8
    elseif dir.z == -1 then -- need to have top facing z+
        -- 4 (z+ face) + 2 (180° rotation)
        return 6
    end
end

-- gives the direction of the node we are attached to
-- according to the facedir param2
local function facedir_to_attached(node)
    local param = node.param2
    local d = vector.zero()
    if param < 4 then -- 0, 1, 2, or 3 is attached to bottom
        d.y = -1
    elseif param >= 20 then -- 20, 21, 22, 23 is attached to ceiling
        d.y = 1
    elseif param == 6 then
        d.z = -1
    elseif param == 8 then
        d.z = 1
    elseif param == 15 then
        d.x = -1
    elseif param == 17 then
        d.x = 1
    else
        error("invalid param2 for graffiti node ".. node.name)
    end
    return d
end

-- #TODO: having the graffiti moving with the node it is attached to could be great !
function g.register_grafitti(name, def)
    def = init_def_values(def)

    -- for compatibility reason, old paint nodes
    core.register_node(
        name, {
            inventory_image = def.image,
            drawtype = "nodebox",
            tiles = { def.image },
            sunlight_propagates = true,
            light_source = def.light or 0,
            floodable = true,
            use_texture_alpha = c_alpha.clip,
            paramtype = "light",
            paramtype2 = "wallmounted",
            groups = {attached_node=1, not_in_creative_inventory=1,
                      grafitti=1, temp_pass = 1},
            buildable_to = true,
            walkable = false,
            node_box = {
                type = "wallmounted",
                wall_top    = {-0.5, 0.49, -0.5, 0.5, 0.5, 0.5},
                wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.49, 0.5},
                wall_side   = {-0.5, -0.5, -0.5, -0.49, 0.5, 0.5},
            },
            pointable = def.pointable,
            drop = {},
    })

    -- new system
    core.register_node(
        name.."_facedir", {
            inventory_image = def.image,
            drawtype = "nodebox",
            tiles = { def.image },
            sunlight_propagates = true,
            light_source = def.light or 0,
            floodable = true,
            use_texture_alpha = c_alpha.clip,
            paramtype = "light",
            paramtype2 = "facedir",
            -- #TODO check the other impacts of change or attached_node..
            groups = {attached_node=2, not_in_creative_inventory=1,
                      grafitti=1, temp_pass = 1},
            buildable_to = true,
            walkable = false,
            node_box = {
                type = "fixed",
                fixed = {-0.5, -0.5, -0.5, 0.5, -0.49, 0.5},
            },
            pointable = def.pointable,
            drop = {},
            -- function to get the direction of the node it is attached to
            _attached_to = facedir_to_attached
    })

    table.insert(_palette.items, { name = name, image = def.image })
end

function g.set_palette_width(width)
    _palette.width = width
end

function g.palette_build(formspec_name)
    local formspec_cols = _palette.width
    local formspec_rows = math.ceil((#_palette.items+1)/formspec_cols)
    local formspec = "size[".. formspec_cols ..",".. formspec_rows .."]"

    for i=1,#_palette.items,1 do
        local name = _palette.items[i].name
        local image = _palette.items[i].image
        local row = math.ceil(i / formspec_cols)-1
        local col = i-1 - math.floor((i-1) / formspec_cols)*formspec_cols
        formspec = formspec .. "image_button_exit[".. col ..","..
            row ..";1,1;".. image ..";".. name ..";]"
    end

    _palette.items = {}
    g._palettes[formspec_name] = formspec

    minetest.register_on_player_receive_fields(
        function(painter, formname, fields)
            if formname ~= formspec_name then return end

            for item,_ in pairs(fields) do
                if core.registered_items[item] then
                    local itemstack = painter:get_wielded_item()

                    if not core.registered_items[itemstack:get_name()].groups.brush then
                        return
                    end

                    local meta = itemstack:get_meta()
                    meta:set_string("grafitti", item)
                    painter:set_wielded_item(itemstack)
                    return
                end
            end
    end)
end

function g.show_palette(painter, formspec_name)
    minetest.show_formspec(painter:get_player_name(), formspec_name,
                           g._palettes[formspec_name])
end

function g.paint(itemstack, user, pointed_thing, palette)
    local player_name = user:get_player_name()
    local meta = itemstack:get_meta()

    if pointed_thing.type ~= "node" then
        return nil
    end

    if minetest.is_protected(pointed_thing.above, player_name)
        or minetest.is_protected(pointed_thing.under, player_name)
    then
        return nil
    end

    local node_under = minetest.get_node(pointed_thing.under)
    local node_under_def = core.registered_items[node_under.name]
    if node_under_def and node_under_def.buildable_to then
        if node_under_def.groups.grafitti then
            minetest.add_node(pointed_thing.under, {name = "air"})
            minetest.sound_play("grafitti_scrape",
                                {pos = pointed_thing.above,
                                 max_hear_distance = 4, gain = 1})
        end
        return nil
    end

    local node_above = minetest.get_node(pointed_thing.above)
    local node_above_def = core.registered_items[node_above.name]
    if node_above_def and not node_above_def.buildable_to then
        return nil
    end

    if node_above_def.groups.grafitti then
        minetest.add_node(pointed_thing.above, {name = "air"})
        minetest.sound_play("grafitti_scrape",
                            {pos = pointed_thing.above,
                             max_hear_distance = 4, gain = 1})
        return nil
    end

    if ( pointed_thing.type == "nothing" or
         meta:get_string("grafitti") == "" ) then
        grafitti.show_palette(user, palette)
        return nil
    end

    minetest.add_node(pointed_thing.above,
                      {
                        name = meta:get_string("grafitti") .. "_facedir",
                        param2 = get_facedir(pointed_thing, user)
                      })

    minetest.sound_play("grafitti_paint",
                        {pos = pointed_thing.above,
                         max_hear_distance = 4, gain = 1})

    if not (EXILE.player_in_creative(user)) then
        itemstack:add_wear(65535/(2000-1))
    end

    return itemstack
end

function g.register_brush(brush_name, def)
    minetest.register_tool(
        brush_name, {
            description = def.description,
            inventory_image = def.inventory_image,
            wield_image = def.wield_image,
            groups = { brush=1 },

            on_place = function(_itemstack, placer, _pointed_thing)
                grafitti.show_palette(placer, def.palette)
            end,

            on_secondary_use = function(_itemstack, user, _pointed_thing)
                grafitti.show_palette(user, def.palette)
            end,

            on_use = function(itemstack, user, pointed_thing)
                return grafitti.paint(itemstack, user, pointed_thing, def.palette)
            end
    })
end
