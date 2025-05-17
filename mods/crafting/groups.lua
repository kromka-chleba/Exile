local S = minetest.get_translator("crafting")

-- initiate groups_table -------------------------------------------------------

-- list og items by crafing group
local groups_table = {}

-- gives access to group_table from outside
-- give a list of all items in a group
function crafting.get_group_items(g_name)
    return groups_table[g_name]
end

-- tells if "item_name" is in "groupname"
function crafting.is_item_in_group (item_name, groupname)
    for _, it in pairs(groups_table[groupname]) do
        if item_name == it then
            return true
        end
    end
    return false
end

-- generate list of items by groups
-- to be called in minetest.register_on_mods_loaded
local function sort_by_group()
    for name, itemdef in pairs(minetest.registered_items) do
        for group_name, value in pairs(itemdef.groups) do
            if value >= 1 then
                if not groups_table[group_name] then
                    groups_table[group_name] = {name}
                else
                    table.insert(groups_table[group_name], name)
                end
            end
        end
    end
end

-- Group names from recipes for the translation script
-- The translation will be performed when descriptions are generated
--[[ Note : cobble's group could be passed as nodes_nature:xxx-cobble1
    item instead of group since we only can drop cobble1 type]]
-- This is for us as human to know what to put in template.
--  by default, desc is group name in code but _ is replaced by " "
local groupNameForTranslations = {
    S("log"), S("fibrous plant"), S("sand"), S("compostable"),
    S("hard wood"), S("cana"), S("woody plant"), S("woodslab"),
    S("bioluminescent"),  S("pottery"),
    S("gravel"),  S("bundleable fiber"),
    S("limestone cobble"), S("basalt cobble"), S("granite cobble"),
    S("ironstone cobble"), S("jade cobble")
}
-- TODO I passed them all first letter uppercase... translation to update

-- groups description
-- if nil, it will be generated in crafting.get_group_stats,
-- changing name_suffix to "name suffix"
local groups_desc = {
    pot = S("Pot") -- used in units
}

-- registering groups description from outside (hello TPH ^^)
function crafting.register_group_desc(name, desc)
    if not name or type(name) ~= "string" then
        core.log ("invalid name in crafting.register_group_desc")
    elseif not desc or type(desc) ~= "string" then
        core.log ("invalid desc in crafting.register_group_desc")
    else
        if groups_desc[name] then
            core.log("warning", "description for " .. name
        .. " already exists and is " .. groups_desc[name]
        .. ". You will erase it with: ".. desc)
        end
        groups_desc[name] = desc
    end
end

-- have to wait for all modules load before generating
-- station lists
minetest.register_on_mods_loaded( function ()
        sort_by_group()
end)


local groups_func = {}
groups_func.__index = groups_func


local function correct_groupnum(gstats, g_num)
    local num = gstats.num
    if not num then return true end -- no stats.num value, can be crafted
    local cmd = gstats.num_cmd
    if num == g_num and not cmd then
        return true -- no "cmd", can be crafted
    end
    -- calculate cmd
    if cmd == "<" and g_num < num then
        return true
    elseif cmd == ">" and g_num > num then
        return true
    end
    return false
end

-- get description or group name or unit
local function get_desc(name)
    if not name or name == "" or name == "empty" then
        return ""
    end
    -- get registered one or generates it
    return groups_desc[name] or S(name:gsub("%_", " ") or "")
end

-- returns table of details relating to information/parameters noted in a string
--[[
Format of `grouptag` is group:<groupname>,<groupnumcondition>/<unit>
    * `groupname` is mandatory name of the group
    * `groupnumcondition` (optional) is required group's number (3,8) or condition (>2 or <6)
    * `unit` (optional) is the unit required. Ex: "pot"

Ex: "group:freshwater,1/pot>"

* Following fields are created:
    * `name` the name of the group (groupname)
    * `tag` is "group:" .. name
    * `num_cmd` (can be nil !) condition ">" or "<". if no command, defautl condition is "="
    * `num` (can be nil !) required group number
    * `correct`  is a function returning `true` if number condition is verified, `false` else.
        Always returns `true` if no number to test.
    * `unit` if present
    ]]
--[[ unlike core default recipe behaviour, multiple groups like
    group:g1,g2
    are not supported yet
    I (lili) still changed our group:g1,numbercondition format to
    group:g1&numbecondition to be able to support it later]]
function crafting.get_group_stats(grouptag)
    -- string must contain "group:" or will return nil
    if not grouptag
            or type(grouptag) ~= "string"
            or grouptag:sub(1,6) ~= "group:" then
        return nil
    end

    local stats = {} -- table of "stats" to return

    -- sterilize grouptage of itemstack parameters
    if grouptag:match(" ") then
        for i=7,#grouptag do -- start at 7th char
            if grouptag:sub(i,i) == " " then -- found it, get only the tag from it
                grouptag = grouptag:sub(1,i-1)
            end
        end
    end

    -- create stats.tag.
    -- ex : "group:vinegar&2/pot"
    stats.tag = grouptag

    -- Checks if we have parameters in grouptag
    -- start after "group:"
    local reader = string.find(grouptag,"[&/]",7)
    if reader then
        -- name is before parameter
        -- ex : "vinegar" from "group:vinegar&2/pot"
        stats.name = grouptag:sub(7,reader-1)
        local separator = grouptag:sub(reader,reader)
        -- check what is next
        if separator == "&" then -- read num parameter
            -- skip ahead to read char after parameter separator
            reader = reader + 1
            -- find end of parameter, being "/" or end of tag
            --[[ Note from lili:
            I got rid of the 3rd parameter as custom description
            because it seemed hard to use (no space, no translation)
            and better to use registered translated desc per group
            ]]
            local end_reader = string.find (grouptag,"/",reader)
            if not end_reader then
                stats.num = grouptag:sub(reader,-1)
            else
                stats.num = grouptag:sub(reader, end_reader-1)
                separator = grouptag:sub(end_reader, end_reader)
                -- skip ahead to read char after parameter separator
                reader = end_reader + 1
            end
        end
        if separator == "/" then -- (else it stayed to , in previous code)
            -- get unit info, taking everything until end of grouptag's string
            stats.unit = grouptag:sub(reader+1, -1)
            -- description for unit
            stats.unit_desc = get_desc(stats.unit)
        end
    end

    -- if we had no paramters and didn't set the name yet
    -- (it happens when no "&" or "/"" but only group name in tag)
    if not stats.name then
        stats.name = grouptag:sub(7,#grouptag)
    end
    if stats.name == "" then
        stats.name = "empty" -- for empty container, allows "group:/pot"
    end

    -- define stats.desc:
    -- use registered one, or generates one
    stats.name_desc = get_desc(stats.name)
    -- generates full desc of grouptag for recipe
    -- TODO comment
    if stats.unit then
        if stats.name_desc == "" then
            stats.desc = S("Any Empty @1", stats.unit_desc)
        else
            stats.desc = S("@1 (Any @2)", stats.name_desc, stats.unit_desc)
        end
    else
        stats.desc = S("Any @1", stats.name_desc)
    end

    -- separate num and condition command
    if stats.num then
        local num = tonumber(stats.num) -- if nil then needs to separate
        if not num then -- separating
            stats.num_cmd = stats.num:sub(1,1) -- command at beginning
            num = tonumber(stats.num:sub(2,#stats.num))
        end
        if not num then -- you did a command too long likely
            -- (should only be 1 char) or placed the command after the number
            error("crafting.get_group_stats: could not properly assess "..
                  "'num' parameter for grouptag: "..stats.grouptag)
        end
        stats.num = num
    end

    -- adding groups function (currently used to check if an item matches this grouptag)
    setmetatable(stats, groups_func)
    return stats
end

-- Tells is item_name or groups match with group condition (gstats)
-- if groups = nil, will be get from item_name's def.groups
-- if item_name is nil, groups is mandatory
-- TODO I could maybe use is_item_in_group ?
groups_func.does_match = function(self, item_name, groups)
    -- parameter checks
    if not item_name and not groups then
        core.log ("warning", "no groups or item to test in groups_func.does_match. Returning nil")
        return
    elseif not groups then
        local def = minetest.registered_items[item_name]
        if not def then
            core.log("invalid item name in groups_func.does_match. Returning false")
            return nil
        else
            groups = def.groups
            -- if item has no groups, return false
            if not groups then
                return false
            end
        end
    elseif type(groups) ~= "table" then
        core.log ("invalid groups table in groups_func.does_match. Returning nil")
    end
-- at this point, groups is not nil and a table
    local g_num = groups[self.name]
    -- if not in groups, stop
    if not g_num or g_num <1 then
        return false
        -- else check correct num if there is a num condition
    elseif not correct_groupnum(self, g_num) then
        return false
    end
    -- check if correct unit is needed
    if self.unit then
        if not groups[self.unit] or groups[self.unit]<1 then
            return false
        end
    end
    -- else everything ok, return true
    return true
end
