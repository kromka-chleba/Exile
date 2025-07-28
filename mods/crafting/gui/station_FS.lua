local S = minetest.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

-- Crafting formspec on tool station -------------------------------------------
--------------------------------------------------------------------------------

-- Generate the formspec outside sfinv
local function make_tool_formspec(player, cache)
    -- get or generates player's cache
    cache = cache or crafting.get_FS_cache(player, true)

    local fs = {"formspec_version[5]",
                --"size[11.2,10.5]" ..
                "size[11.4,10]",
                "position[0.5,0.5]"}

    -- displaying creator above formspec
    -- #TODO dirty, do better once we decide on definitive behavior
    if cache.station and (cache.sTool ~= crafting.default_tool) then
        local desc = cache.station.desc
        if desc then
            local title = S("You are using: @1", desc)
            local creator = cache.station.creator
            if creator then
                title =  title .. "  |  " .. S("Crafted by: @1", creator)
            end
            fs[#fs + 1] = "tabheader[0,0;station_tab;" .. title .. ";1;;]"
        end
    end

    fs[#fs + 1] = crafting.make_crafting_formspec(player)

    return tofstring(fs)
end

crafting.make_tool_formspec = make_tool_formspec

function crafting.show_station_formspec(player, player_name)
    core.show_formspec(player_name,'exile:crafting',
                    crafting.make_tool_formspec(player))
end

-- return craftedby info for the given station, nil if not found
-- #TODO not sure it should stay on gui.lua
local function get_station_info(station, pos)
    -- if no station, no tag
    if station == nil then
        -- in crafting.refresh_recipes_FS() cache.station must not be nil
        return {}
    end
    -- #TODO (for lili) go check on that
    -- see tech/stations for why we check _station or remove letters from name
    local idef = core.registered_items[station._tool]
        or core.registered_items[station:sub(1,-8)]
        or core.registered_items[station]

    local creator = nil
    local desc = nil
    -- if station is registered and has a groups field
    if idef then
        -- #TODO how do I get the short description ??
        desc = ItemStack(idef.name):get_short_description()
        if idef.groups then
            -- if there is a craftby field or savemeta in groups
            if idef.groups.craftedby or idef.groups.savemeta then
                local meta = core.get_meta(pos)
                -- get creator string for craftedby mechanics
                if meta then
                    creator = meta:get_string("creator")
                end
            end
        end
    end
    -- return nil if not found
    return {desc = desc, creator = creator}
end

-- generates cache and set it for crafting formspec for crafting by hand and
-- with an optional tool 'placed_tool'
local function cache_on_station(player, placed_tool, pos)
    -- get or generate cache if non existent
    local cache = crafting.get_FS_cache(player, true)
    -- don't have refresh recipe button but display directly craftable state
    cache.updated = true
    cache.closed = false -- formspec opened

    -- adds station info
    cache.station = get_station_info(placed_tool, pos)
    -- generates corresponding tools list
    cache.tool_list = crafting.generate_tools_list(placed_tool)
    -- updates cache with new selected `placed_tool` as tool (could be empty)
    cache:set_tool(placed_tool)
end

local function cache_off_station(player)
    -- get cache if existent
    local cache = crafting.get_FS_cache(player)
    -- set station, tools, tabs and recipes
    cache:set_station(nil)
end

-- used when inventory tab was opened with right click on a tool or on
-- crafting ground
minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname ~= 'exile:crafting' then return false; end -- Not our form.

        local player_name = player:get_player_name()
        -- additional stuffs to run before main fields.quit action
        if fields.quit then
            cache_off_station(player)
            crafting.close_crafting_formspec(player)
            sfinv.set_player_inventory_formspec(player)
            return true -- stop running functions
        end
        -- if other action than close was made, reshow the formspec
        if crafting.process_receive_fields(player, formname, fields) then
            local formspec = make_tool_formspec(player)
            if formspec then
                minetest.show_formspec(player_name,'exile:crafting',formspec)
            end
        end
end)

-- display craft form on right click on a tool node or only for
-- crafting types supported by tech:hand - with node == {}
function crafting.crafting_item_on_rightclick(pos,node,clicker,
                                              itemstack,pointed_thing)
    -- #TODO this function requires only a name not a node or pointed_thing
    assert(node, "crafting.crafting_item_on_rightclick: invalid node provided")
    local tool_name = node.name

    -- did a player click?
    if not minetest.is_player(clicker) then
        return
    end

    -- tool_name must be nil or refer to a node with crafting properties set
    if not tool_name == nil then
        local def = minetest.registered_nodes[tool_name]
        if not def or not def.exile_crafting then
            error("invalid crafting tool: " .. tool_name)
        end
    end
    -- update cache before showing formspec
    cache_on_station(clicker, tool_name, pos)

    -- generates and shows station's formspec
    local formspec = make_tool_formspec(clicker)
    local player_name = clicker:get_player_name()
    minetest.show_formspec(player_name,'exile:crafting',formspec)

    return itemstack
end

-- set minimal's function to open crafting formspec on right click with empty
-- hand on a proper crafting ground
minimal.set_crafting_ground_on_rightclick(crafting.crafting_item_on_rightclick)
