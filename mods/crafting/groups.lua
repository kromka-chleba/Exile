local S = minetest.get_translator("crafting")

-- Group names from recipes for the translation script
-- The translation will be performed when descriptions are generated
-- Note : cobble's group could be passed as nodes_nature:xxx-cobble1
--   item instead of group since we only can drop cobble1 type
-- #TODO do we need it this we translation group desc in gstat ?
-- This is for us as human, by default, desc is group name in code but _ is replaced by " "
local groupNameForTranslations = {
    S("log"), S("fibrous plant"), S("sand"), S("compostable"),
    S("hard wood"), S("cana"), S("woody plant"), S("woodslab"),
    S("bioluminescent"),  S("pottery"),
    S("gravel"),  S("bundleable fiber"),
    S("limestone cobble"), S("basalt cobble"), S("granite cobble"),
    S("ironstone cobble"), S("jade cobble"),
    S("freshwater pot"), -- group:freshwater_pot
    S("pot"), -- group:pot (TODO not existing yet)
    S("bowl") -- group:bowl TODO
}

--returns table of details relating to information/parameters noted in a string
--[[permits format of: group:<groupname>,<groupnumcondition>,<desc>
    * groupname being the group that is necessary
    * groupnumcondition is the required group's number (3,8) or condition (>2 or <6)
    * desc being a custom description (recipe-local) for what the group should be called. desc is translated.

    * custom 'correct' function allows one to determine groupnumcondition values that have a condition

    * following can become indexes of 'stats':
    'name', 'tag', 'num' (number), 'num_cmd', 'desc', 'correct' (function)
    num and num_cmd will NOT always be valid indexes
    ]]
function crafting.get_group_stats(grouptag)
    -- string must contain "group:" or will return nil
    if not grouptag
            or type(grouptag) ~= "string"
            or grouptag:sub(1,6) ~= "group:" then
        return nil
    end
    --grouptag = grouptag:sub(7,#grouptag) -- remove 'group:'
    local str_len = #grouptag
    local stats = {} -- table of "stats" to return
    -- has parameters to check through
    if string.match(grouptag,",") then
        local reader = 7 -- start at 7th character, after "group:"
        while true do -- use while loop for custom iterator addition+remove
            if reader >= str_len then break end -- stop if we're over string length
            local read_char = grouptag:sub(reader,reader)
            if read_char == "," then -- found parameter
                if not stats.tag then -- create stats.tag
                    stats.tag = grouptag:sub(1,reader-1)
                end
                reader=reader+1 -- skip ahead to read char after parameter separator
                if not stats.num then -- assume 1st parameter is custom group num
                    stats.num = ""
                    -- add to stats num value with found characters until end
                    for i=reader,str_len do
                        read_char = grouptag:sub(i,i)
                        if read_char == "," then
                            break -- found end via new parameter line, end
                        end
                        stats.num = stats.num..read_char
                    end
                    reader=reader+(#stats.num)-1 -- subtract 1 to get parameter lines properly
                elseif not stats.desc then
                    -- assume 2nd parameter is custom description
                    stats.desc = ""
                    for i=reader,str_len do
                        read_char = grouptag:sub(i,i)
                        if read_char == "," then break end
                        stats.desc = stats.desc..read_char
                    end
                    reader=reader+(#stats.desc)-1
                else -- no more commands to do, end iteration
                    break
                end
            end
            reader=reader+1 -- gradually increase to iterate through string
        end
    end
    -- if no stats.tag set by parameter line then assume normal
    if not stats.tag then
        stats.tag = grouptag
    end
    -- sterilize of itemstack parameters
    if stats.tag:match(" ") then
        for i=7,#stats.tag do -- start at 7th char
            if stats.tag:sub(i,i) == " " then -- found it, get only the tag from it
                stats.tag = stats.tag:sub(1,i-1)
            end
        end
    end
    -- set up group name
    stats.name = stats.tag:sub(7,#stats.tag)
    -- revert to name
    if not stats.desc then
        -- Add a translation of the group name
        stats.desc = S(stats.name:gsub("%_", " ") or "")
    end
    -- remove nil indexes
    for stat,val in pairs(stats) do
        if val == "" or val:lower() == "nil" then
            stats[stat] = nil
        end
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
    -- add "correct" function to determine whether or not the
    --  group-based item can be used for crafting
    stats.correct = function(amount)
        local num = stats.num
        if not num then return true end -- no stats.num value, can be crafted
        local cmd = stats.num_cmd
        if num == amount and not cmd then
            return true -- no "cmd", can be crafted
        end
        -- calculate cmd
        if cmd == "<" and amount < num then
            return true
        elseif cmd == ">" and amount > num then
            return true
        end
        return false
    end
    return stats
end

-- initiate groups_table -------------------------------------------------------

-- list og items by crafing group
local groups_table = {}

-- gives access to group_table from outside
function crafting.get_group_items(g_name)
    return groups_table[g_name]
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

minetest.register_on_mods_loaded( function ()
        sort_by_group()
end)
