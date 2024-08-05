-- check infotext_get_base_string or infotext_set for usages

minimal=minimal -- only used to extend the namespace
local S=minimal.S

-- MISCELLANEOUS INFOTEXT FUNCTIONS

-- uses or creates an itemstack to get proper description
local function get_desc(stack)
  -- confirm if string, or check if pos (won't have .name) and get nodedef
  -- if a table or userdata still, then default to just stack
  stack = type(stack) == "string" and stack or
    (type(stack) == "table" and type(stack.name) ~= "string") and minimal.get_nodedef(stack) or
    (type(stack) == "userdata" or type(stack) == "table") and stack
  -- if a string then create ItemStack with, if a table then create an ItemStack with the name
  -- if already a userdata, assume it is an ItemStack
  stack = type(stack) == "string" and ItemStack(stack) or type(stack) == "table" and stack.name and ItemStack(stack.name)
    or type(stack) == "userdata" and stack
  -- couldn't get itemstack, return nil
  if not stack then return end
  -- prefer short description
  return stack:get_short_description()
end

-- clears out empty strings (e.g. "")
function minimal.infotext_purify_params(params)
  if type(params) ~= "table" then return params end
  for name,value in pairs(params) do
    -- clear out empty strings
    params[name] = value ~= "" and value or nil
  end
  return params
end

-- either gets a params from meta, or if provided params; 
-- returns the params mixed with the values from meta (params indexes prioritized)
function minimal.infotext_update_params(meta, params)
  -- create new params if it isn't a table
  if type(params) ~= "table" then
    params = meta:to_table()
    params = type(params) == "table" and params.fields
  -- merge params with old meta
  else
    local merge_params = meta:to_table()
    -- merge with current meta or if unable to get table, return regular params
    params = merge_params and minimal.merge_tables(merge_params.fields, params) or params
  end
  return params
end
-- local quick access
local infotext_upd_params = minimal.infotext_update_params

-- filters and sets up base param values (description, owner, label)
-- translation handled, now for the programmer to organize them how they wish
function minimal.infotext_get_base_params(stack, meta, params)
  -- create params if does not exist
  params = type(params) == "table" and params or infotext_upd_params(meta)
  if not params then return end -- no params to use
  -- get proper description if description not provided
  params.description = params.description or params.desc or get_desc(stack)
  -- set up params w/ translations
  params.owner = (params.owner and params.owner ~= "") and S("Owner:").." "..params.owner
  params.label = (params.label and params.label ~= "") and S("Label:").." "..params.label
  return params
end

-- PRIMARY INFOTEXT FUNCTIONS

-- clears infotext to a nil string
function minimal.infotext_clear(pos,meta)
  -- use provided metadata or get one
  meta = type(meta) == "userdata" and meta or minetest.get_meta(pos)
	meta:set_string("infotext","")
end

-- itemstack, nodemeta, 'params' table
-- itemstack is used to determine description - but can also be pos, table, or string
-- sends a formatted string for basic infotext
function minimal.infotext_get_base_string(stack, meta, params)
  -- get filtered params
  params = type(params) == "table" and table.copy(params) or nil -- don't overwrite provided params table
  params = minimal.infotext_get_base_params(stack, meta, params)
  -- create and return full infotext
  return (params.description or "")..
    ( ( params.owner and "\n"..params.owner ) or "" ).. -- only apply owner if available
    ( ( params.label and "\n"..params.label ) or "" ) -- only apply label if available
end

-- sets infotext string according to the node's or provided function's logic
-- if no logic, defaults to base infotext
-- func, nodedef, and stack are optional
-- func can be provided for determining infotext logic, nodedef for checking a node's definition,
-- stack for base infotext logic
-- meta and params are somewhat optional
-- function expects them to be provided, but will get meta from provided pos, and will create a params to be used
-- returns false on failure, infotext string on success
function minimal.infotext_set_new(pos, meta, params, func, nodedef, stack)
  nodedef = type(nodedef) == "table" and nodedef or minimal.get_nodedef(pos) -- just to confirm
  if type(nodedef) ~= "table" then return false end -- no success
  stack = type(stack) == "userdata" and stack or nodedef -- allow for itemstackstack option or default to nodedef table
  -- get meta
  meta = type(meta) == "userdata" and meta or minetest.get_meta(pos)
  -- use or get params
  params = type(params) == "table" and params or infotext_upd_params(meta)
  params = minimal.infotext_purify_params(params) -- remove empty strings
  -- custom function or nodedef on_infotext function
  func = type(func) == "function" and func or type(nodedef.on_infotext) == "function" and nodedef.on_infotext
  -- infotext will be the provided func
  local infotext = func and func(pos, nodedef, meta, params) or nil
  -- if false then return false
  if infotext == false then
    return false
  -- otherwise didn't get string, do infotext base
  elseif type(infotext) ~= "string" then
    infotext = minimal.infotext_get_base_string(stack, meta, params)
  end

  if type(infotext) ~= "string" then return false end
  meta:set_string("infotext",infotext)
  return infotext
end
