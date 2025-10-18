local c_alpha = minimal.compat_alpha

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

function g.register_grafitti(name, def)
    def = init_def_values(def)

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
            -- legacy_wallmounted = true, -- for maps before 2012
            drop = {},
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

            for item,v in pairs(fields) do
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

    local dir = vector.direction(pointed_thing.above, pointed_thing.under)
    local wallmounted = minetest.dir_to_wallmounted(dir)
    minetest.add_node(pointed_thing.above,
                      {name = meta:get_string("grafitti"), param2=wallmounted})
    minetest.sound_play("grafitti_paint",
                        {pos = pointed_thing.above,
                         max_hear_distance = 4, gain = 1})

    if not (minimal.player_in_creative(user)) then
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

            on_place = function(itemstack, placer, pointed_thing)
                grafitti.show_palette(placer, def.palette)
            end,

            on_secondary_use = function(itemstack, user, pointed_thing)
                grafitti.show_palette(user, def.palette)
            end,

            on_use = function(itemstack, user, pointed_thing)
                return grafitti.paint(itemstack, user, pointed_thing, def.palette)
            end
    })
end
