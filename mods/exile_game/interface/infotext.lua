-- check infotext_get_base_string or infotext_set for usages

local S=EXILE.S

-- MISCELLANEOUS INFOTEXT FUNCTIONS

-- uses or creates an itemstack to get proper description
local function get_desc(stack)
    -- confirm if string, or check if pos (won't have .name) and get nodedef
    -- if a table or userdata still, then default to just stack
    stack = type(stack) == "string" and stack
        or  (type(stack) == "table"
             and type(stack.name) == "string"
             and minetest.registered_nodes[stack.name] )
        or (type(stack) == "userdata" or type(stack) == "table") and stack
    -- if a string then create ItemStack with,
    --   if a table then create an ItemStack with the name
    -- if already a userdata, assume it is an ItemStack
    stack = type(stack) == "string" and ItemStack(stack)
         or type(stack) == "table" and stack.name and ItemStack(stack.name)
        or type(stack) == "userdata" and stack
    -- couldn't get itemstack, return nil
    if not stack then return end
    -- prefer short description
    return stack:get_short_description()
end

-- clears out empty strings (e.g. "")
function EXILE.infotext_purify_params(params)
    if type(params) ~= "table" then return params end
    for name,value in pairs(params) do
        -- clear out empty strings
        params[name] = value ~= "" and value or nil
    end
    return params
end

-- either gets a params from meta, or if provided params;
-- returns params mixed with values from meta (params indexes prioritized)
function EXILE.infotext_update_params(meta, params)
    -- create new params if it isn't a table
    if type(params) ~= "table" then
        params = meta:to_table() -- returns a table or nil on failure
        params = params and params.fields -- now nil or table
    -- else merge params with old meta
    else
        local meta_params = meta:to_table()
        -- merge params with current meta fields if some are present
        -- params fields will override meta fields
        if meta_params then
            params = EXILE.merge_tables(meta_params.fields, params)
        end
    end
    return params
end

-- local quick access
local infotext_upd_params = EXILE.infotext_update_params

-- filters and sets up base param values (description, owner, label)
-- translation handled, now for the programmer to organize them how they wish
function EXILE.infotext_get_base_params(stack, meta, params)
    -- create params from meta table if does not exist
    if type(params) ~= "table" then
        params = infotext_upd_params(meta)
    end
    -- if still no params, stop
    if not params then return end
    -- get proper description if description not provided
    params.description = params.description or params.desc or get_desc(stack)
    -- set up params w/ translations
    params.owner = (params.owner and params.owner ~= "")
        and S("Owner:").." "..params.owner
    params.label = (params.label and params.label ~= "")
        and S("Label:").." "..params.label
    return params
end

-- PRIMARY INFOTEXT FUNCTIONS

-- clears infotext to a nil string
function EXILE.infotext_clear(pos,meta)
    -- use provided metadata or get one
    meta = type(meta) == "userdata" and meta or minetest.get_meta(pos)
    meta:set_string("infotext","")
end

-- itemstack, nodemeta, 'params' table
--   itemstack is used to determine description
--   but can also be pos, table, or string

-- sends a formatted string for basic infotext
function EXILE.infotext_get_base_string(stack, meta, params)
    -- get filtered params
    if type(params) == "table" then
        -- don't overwrite provided params table
        params = table.copy(params)
    else
        params = nil
    end

    params = EXILE.infotext_get_base_params(stack, meta, params)
    -- create and return full infotext
    return (params.description or "")..
        ( ( params.owner and "\n"..params.owner )
            or "" ).. -- only apply owner if available
        ( ( params.label and "\n"..params.label )
            or "" ) -- only apply label if available
end

-- sets infotext string according to the node's or provided function's logic
-- if no logic, defaults to base infotext
-- func, nodedef, and stack are optional
-- func can be provided for determining infotext logic,
--  nodedef for checking a node's definition,

-- stack for base infotext logic
-- meta and params are somewhat optional
-- function expects them to be provided,
--   but will get meta from provided pos, and will create a params to be used

-- returns false on failure, infotext string on success
function EXILE.infotext_set_new(pos, meta, params, func, nodedef, stack)
    -- get meta if not given
    if type(meta) ~= "userdata" then
        meta = minetest.get_meta(pos)
    end
    -- get params from meta table if not provided
    if type(params) ~= "table" then
        params = infotext_upd_params(meta)
    end
    -- remove empty strings
    params = EXILE.infotext_purify_params(params)

    -- get nodedef/stack
    if type(nodedef) ~= "table" then
        nodedef = EXILE.get_nodedef(pos) -- just to confirm
    end
    -- stop if we failed to get a proper nodedef
    if type(nodedef) ~= "table" then return false end
    -- allow for itemstackstack option or default to nodedef table
    if type(stack) ~= "userdata" then
        stack = nodedef
    end

    -- custom function or nodedef on_infotext function
    if type(func) ~= "function" then
        func = nodedef.on_infotext
    end

    -- get infotext from provided function, if valid function, nil else
    local infotext = nil
    if type(func) == "function" then
        infotext = func(pos, nodedef, meta, params)
    end
    -- if false then return false
    if infotext == false then
        return false
    -- if the function returned an invalid string, or we had no function
    -- use default infotext
    elseif type(infotext) ~= "string" then
        infotext = EXILE.infotext_get_base_string(stack, meta, params)
    end

    meta:set_string("infotext",infotext)
    return infotext
end
