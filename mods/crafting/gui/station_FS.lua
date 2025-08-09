local S = minetest.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

-- Crafting formspec on tool station -------------------------------------------
--------------------------------------------------------------------------------

-- generates a table to be stored in cache, with following fields:
-- `name`: the name of the station (has to be a valid station)
-- `title`: string to be displayed above the formspec
-- pos is needed to get the meta for the creator (craftedby meta)
local function get_station_info(station_name, pos)
    -- if no station, no tag
    if station_name == nil then
        return {}
    end
    -- get placed_tool's description and creator
    -- we get item's description because we want "lili's hammer"
    -- not "lili's placed hammer"
    local idef = core.registered_items[station_name._tool]
        or core.registered_items[station_name:sub(1,-8)]
        or core.registered_items[station_name]

    -- generate a tab title with placed_tool's info
    local creator = nil
    local desc = nil
    -- if station is registered and has a groups field
    if idef then
        desc = ItemStack(idef.name):get_short_description()
        -- if no pos, no craftedby meta
        if pos and idef.groups then
            -- if there is a craftby field or savemeta in groups
            if idef.groups.craftedby or idef.groups.savemeta then
                local meta = core.get_meta(pos)
                -- get creator string for craftedby mechanics
                if meta then
                    creator = meta:get("creator")
                end
            end
        end
    end
    -- generate a title with desc and creator
    local title = nil
    if desc then
        title = S("You are using: @1", desc)
    end
    if creator then
        if title then
            title = title .. "  |  "
        else
            title = ""
        end
        title =  title .. S("Crafted by: @1", creator)
    end
    -- return nil in desc and creator fields if not found
    return {name = station_name, title = title}
end

-- Generate the formspec outside sfinv
--[[
    * `fs_name` is the name of the formspec. nil if not open
    * `station` is a table with following fields:
    {
    `name`: the name of the station (has to be a valid station)
    `title`: string to be displayed above the formspec
    }
    it is optional, if not provided, we will use the default bare hands
    * `cache` is optional and will be get from player if not given
-- ]]
local function make_tool_formspec(player, station, cache)

    -- set formspec size
    local fs = {"formspec_version[5]",
                --"size[11.2,10.5]" ..
                "size[11.4,10]",
                "position[0.5,0.5]"}

    -- displaying station's descritpion and creator above formspec
    if station and station.title then
        fs[#fs + 1] = "tabheader[0,0;station_tab;" .. station.title .. ";1;;]"
    end

    -- initiates FS_cache[player_name] if non existant
    cache = cache or crafting.get_FS_cache(player, true, station)

    -- updates station info if we changed station
    if cache.station ~= station then
        cache:set_station(station)
    end

    -- generates the inside of the formspec
    fs[#fs + 1] = crafting.make_crafting_formspec(player, cache)
    -- returns the full formspec string
    return tofstring(fs)
end

crafting.make_tool_formspec = make_tool_formspec

-- generates/refreshes and shows the station crafting formspec
-- `fs_name` is the name of the formspec ("exile:crafting" by default)
local function show_station_formspec(player, station, fs_name)
    -- open it with "exile:crafting" name by default
    fs_name = fs_name or "exile:crafting"
    -- initiates FS_cache[player_name] if non existant
    local cache = crafting.get_FS_cache(player, true, station)

    -- flag formspec as open (or not if fs_name = nil)
    cache.open = fs_name

    -- updates formspec content
    local fs = make_tool_formspec(player, station, cache)
    -- display it
    core.show_formspec(player:get_player_name(), fs_name, fs)
end

crafting.show_station_formspec = show_station_formspec

-- used to reset cache to "no station" when we leave a station
-- in order to update sfinv part properly for next inv opening
-- (could be improved, this is in case we left with default tool open)
local function cache_off_station(player, cache)
    cache:set_station(nil)
    -- update sfinv, so we keep current tab if we changed it in {}
    sfinv.set_player_inventory_formspec(player)
end

-- callback for any station crafting formspec
local function process_station_fields(player, formname, fields)
    local cache = crafting.process_receive_fields(player, formname, fields)
    if cache then
        if fields.quit then
            -- additionnal reset of station if needed
            -- Following line could go if no sfinv opening is allowed anymore
            cache_off_station(player, cache)
        else
            -- updates formspec content
            local fs = make_tool_formspec(player, cache.station, cache)
            -- display it
            core.show_formspec(player:get_player_name(), formname, fs)
        end
    end
end

crafting.process_station_fields = process_station_fields

-- used when inventory tab was opened with right click on a tool or on
-- crafting ground
minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname ~= 'exile:crafting' then
            return false -- Not our form.
        else
            process_station_fields(player, formname, fields)
            return true
        end
end)

-- display craft form on right click on a tool node or only for
-- crafting types supported by tech:hand - with node == {}
function crafting.crafting_item_on_rightclick(pos,node,clicker,
                                              itemstack,pointed_thing)

    if type(node) ~= "table" then
        core.log("crafting.crafting_item_on_rightclick: invalid node provided")
        return
    end

    -- did a player click?
    if not minetest.is_player(clicker) then
        return
    end

    local station_name = node.name
    -- station must be nil or refer to a node with crafting properties set
    if station_name ~= nil then
        local def = minetest.registered_nodes[station_name]
        if not def or not def.exile_crafting then
            error("invalid crafting tool: " .. station_name)
        end
    end
    -- updates station's name and title (table)
    local station = get_station_info(station_name, pos)
    -- generates and shows station's formspec
    show_station_formspec(clicker, station, 'exile:crafting')

    return itemstack
end

-- set minimal's function to open crafting formspec on right click with empty
-- hand on a proper crafting ground
minimal.set_crafting_ground_on_rightclick(crafting.crafting_item_on_rightclick)
