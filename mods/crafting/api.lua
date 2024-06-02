-- Crafting Mod - semi-realistic crafting in minetest
-- Copyright (C) 2018 rubenwardy <rw@rubenwardy.com>
--
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- This library is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA


-- Warning: this is a circular dependency; minimal depends on crafting, too
--minimal = minimal

crafting = {
	recipes = {},
	tab_labels = {},
	recipes_by_id = {},
	recipes_by_output = {},
	registered_on_crafts = {},
	item_by_group = {}, -- hash group:groupname to an item name. only last inventory item from group is stored.
	sort_order_by_player = {}, -- hash of recipe id to display order in sorted array
}

local S = minetest.get_translator("minimal")

function crafting.register_type(name, label)
	crafting.recipes[name] = {}
	-- add a label for tabs - default to the name
	crafting.tab_labels[name] = (label or name)
end

function crafting.register_recipe(def)
  -- multiple output items unsupported due to minimal/interface/inventory.lua limitations, do replace instead
	assert(type(def.output) == "string", "Output needed in recipe definition (string only)")
	assert(def.type,   "Type needed in recipe definition")
	assert(def.items,  "Items needed in recipe definition")

	def.level = def.level or 1
	-- Can be more then one craft station for a recipe
	-- Need to store as a table.
	if type(def.type) == 'string' then
		def.type = { def.type }
	end
  -- convert into table to iterate through
  if type(def.replace) ~= "table" then
    def.replace = {def.replace}
  end
        def.id = #crafting.recipes_by_id + 1
	crafting.recipes_by_output[def.output] = def
	crafting.recipes_by_id[def.id] = def
	return def.id
end

-- have to wait for all modules load before generating
-- station lists
minetest.register_on_mods_loaded( function ()
	for _,recipe in ipairs(crafting.recipes_by_id) do
		if type(recipe.type) == "string" then
			recipe.type = { recipe.type }
		end
		for _,station in ipairs(recipe.type) do
			local tab = crafting.recipes[station]
			assert(tab,        "Unknown craft type " .. station)
			tab[#tab + 1] = recipe
		end
	end
end)


local unlocked_cache = {}
function crafting.get_unlocked(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		minetest.log("warning", "Crafting doesn't support getting unlocks for offline players")
		return {}
	end

	local retval = unlocked_cache[name]
	if not retval then
		retval = minetest.parse_json(
			player:get_meta():get("crafting:unlocked") or "{}")
		unlocked_cache[name] = retval
	end

	assert(retval)

	return retval
end

if minetest then
	minetest.register_on_leaveplayer(function(player)
		unlocked_cache[player:get_player_name()] = nil
	end)
end

local function write_json_dictionary(value)
	if next(value) then
		return minetest.write_json(value)
	else
		return "{}"
	end
end

function crafting.lock_all(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		minetest.log("warning", "Crafting doesn't support setting unlocks for offline players")
		return {}
	end

	local unlocked = crafting.get_unlocked(name)

	for key, _ in pairs(unlocked) do
		unlocked[key] = nil
	end

	unlocked_cache[name] = unlocked

	player:get_meta():set_string("crafting:unlocked", write_json_dictionary(unlocked))
end

function crafting.unlock(name, output)
	local player = minetest.get_player_by_name(name)
	if not player then
		minetest.log("warning", "Crafting doesn't support setting unlocks for offline players")
		return {}
	end

	local unlocked = crafting.get_unlocked(name)

	if type(output) == "table" then
		for i=1, #output do
			unlocked[output[i]] = true
			minetest.chat_send_player(name, "You've unlocked " .. output[i])
		end
	else
		unlocked[output] = true
		minetest.chat_send_player(name, "You've unlocked " .. output)
	end

	unlocked_cache[name] = unlocked
	player:get_meta():set_string("crafting:unlocked", write_json_dictionary(unlocked))
end

function crafting.get_recipe(id)
	return crafting.recipes_by_id[id]
end

-- returns a table of details relating to information/parameters noted in a string
-- permits format of:
-- group:<groupname>,<groupnumcondition>,<desc>
-- groupname being the group that is necessary
-- groupnumcondition being the required group's number (3, 8) or a condition (>2 or <6)
-- desc being a custom description (recipe-local) for what the group should be called
-- custom 'correct' function allows one to determine groupnumcondition values that have a condition
-- following can become indexes of 'stats': 'name', 'tag', 'num' (number), 'num_cmd', 'desc', 'correct' (function)
-- num and num_cmd will NOT always be valid indexes
function crafting.get_group_stats(grouptag)
  -- string must contain "group:" or will return nil
  grouptag = (type(grouptag) == "string" and grouptag:sub(1,6) == "group:") and grouptag or nil
  if not grouptag then return end
  --grouptag = grouptag:sub(7,#grouptag) -- remove 'group:'
  local str_len = #grouptag
  local stats = {} -- table of "stats" to return
  -- has parameters to check through
  if string.match(grouptag,",") then
    local reader = 7 -- start at 7th character, after "group:"
    while true do -- use while loop for custom iterator addition+remove
      if reader >= str_len then break end -- end reading if we're over string length
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
            if read_char == "," then break end -- found end via new parameter line, end
            stats.num = stats.num..read_char
          end
          reader=reader+(#stats.num)-1 -- subtract 1 to get parameter lines properly
        elseif not stats.desc then -- assume 2nd parameter is custom description
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
    stats.desc = stats.name:gsub("%_", " ")
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
    if not num then -- you did a command too long likely (should only be 1 char) or placed the command after the number
      error("crafting.get_group_stats: could not properly assess 'num' parameter for grouptag: "..stats.grouptag)
    end
    stats.num = num
  end
  -- add "correct" function to determine whether or not the group-based item can be used for crafting
  stats.correct = function(amount)
    local num = stats.num
    if not num then return true end -- no stats.num value, can be crafted
    local cmd = stats.num_cmd
    if num == amount and not cmd then return true end -- no "cmd", can be crafted
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

function crafting.peek_item(item, item_hash)
	local items = {}
	-- single item peeks need to be in table for processing
	if (type(item) ~= 'table') then
		item = { item }
	end
	for _, item in ipairs(item) do
    local gstats = crafting.get_group_stats(item)
		local stack = ItemStack(item)
    local def = table.copy(stack:get_definition())
    def.name = gstats and gstats.tag or def.name
    def.description = (gstats and S("Any @1",gstats.desc)) or def.description
    def._orig_desc = def._orig_desc or def.description
		local need =  stack:get_count()
		local have = item_hash[def.name] or 0
    -- has a specified number (and have isn't 0, don't search unnecessarily)
    if have ~= 0 and (gstats and gstats.num) then
      have = item_hash[gstats.tag..gstats.num] or 0
      local cmd = gstats.num_cmd
      -- found command, check anew
      if cmd then
        have = 0
        -- start at gstats.num (-1 if less, otherwise +1), if less than, work down to 1 (-1), otherwise check until 256
        for i = (cmd == "<" and gstats.num-1 or gstats.num+1), (cmd == "<" and 1 or 256), (cmd == "<" and -1 or 1) do
          have = have + (item_hash[gstats.tag..i] or 0)
        end
      end
    end
		items[#items + 1] = {
			name = def.name,
			have = have,
			need = need,
			available = (have >= need) and true or false,
      description = def.description,
      short = def._orig_desc,
		}
	end
	return items
end

local function get_real_name(name)
	if name:sub(1, 6) == "group:" then
		return crafting.item_by_group[name]
	end
	return name
end


function crafting.get_all(ctype, level, item_hash, unlocked)
	assert(crafting.recipes[ctype], "No such craft type!")
	local results = {}
	for _, recipe in pairs(crafting.recipes[ctype]) do
		local craftable = true
		if recipe.level <= level and (recipe.always_known or unlocked[recipe.output]) then
			local items = {}
			-- Check what ingredients are available
			for recipe_row, rowItem in ipairs(recipe.items) do
				local rItems = {} -- row items
				local pickable = false
				for i,item in ipairs(crafting.peek_item(rowItem, item_hash)) do
					rItems[#rItems+1] = item
					if item.available then
						pickable = true -- at least one item is available
					end
				end
				items[recipe_row]=rItems -- save items by recipe input row
				if not pickable then
					craftable = false -- don't have any of the needed ingredients from this row.
				end
			end
			-- check if we have a where clause only if its craftable
			if craftable and recipe.where then
				craftable = false -- assume this failes unless we find a match.
				-- recipe.where should look something like this:  @1.material == @2.material
				-- @x where x is the input item row number
				local lParam, lKey, test, rParam, rKey = 
					string.match(recipe.where, "@(%d+)%.(%w+)%s*(.-)%s*@(%d+)%.(%w+)$")
				for _,left in ipairs( items[tonumber(lParam)] ) do
					local lName = get_real_name(left.name)
					if left.available then
						for _,right in ipairs(items[tonumber(rParam)]) do
							local rName = get_real_name(right.name)
							if right.available then
								local left_def = ItemStack(lName):get_definition()
								local lValue = left_def.exile_crafting[lKey] 
								local right_def = ItemStack(rName):get_definition()
								local rValue = right_def.exile_crafting[rKey]
								-- find the operator
								if test == '==' and lValue == rValue then
									craftable = true
								end
								if test == '~=' and lValue ~= rValue then
									craftable = true
								end
							end
						end
					end
				end
			end

			results[#results + 1] = {
				recipe    = recipe,
				items     = items,
				craftable = craftable,
			}
		end
	end

	return results
end


function crafting.set_item_hashes_from_list(inv, listname, item_hash)
	for _, stack in pairs(inv:get_list(listname)) do
		if not stack:is_empty() then
			local itemname = stack:get_name()
			item_hash[itemname] = (item_hash[itemname] or 0) + stack:get_count()
			local def = minetest.registered_items[itemname]
			if def and def.groups then
				for groupname,groupvalue in pairs(def.groups) do
					local group = "group:" .. groupname
					crafting.item_by_group[group] = itemname
					item_hash[group] = (item_hash[group] or 0) + stack:get_count()
          -- alternative for pickier crafts (adds preferred number)
          item_hash[group..groupvalue] = (item_hash[group..groupvalue] or 0) + stack:get_count()
				end
			end
		end
	end
end

function crafting.get_all_for_player(player, ctype, level)
	local unlocked = crafting.get_unlocked(player:get_player_name())
	-- build player items hash
	local item_hash = {}
	-- reset group hash
	crafting.item_by_group = {}
	crafting.set_item_hashes_from_list(player:get_inventory(), "main", item_hash)
	-- Get all available recipies and mark craftible ones.
	local results =  crafting.get_all(ctype, level, item_hash, unlocked)
	return results
end

function crafting.can_craft(name, ctype, level, recipe)
	local unlocked = crafting.get_unlocked(name)
	if type(ctype) == 'string' then
		ctype = { ctype }
	end
	local rtypes = recipe.type
	if type(recipe.type) == 'string' then
		rtypes = { recipe.type }
	end
	for _,station in ipairs(ctype) do
		for _,rec_type in ipairs(rtypes) do
			if rec_type == station and recipe.level <= level and
					(recipe.always_known or unlocked[recipe.output]) then
				return true
			end
		end
	end
	return false
end

local function give_all_to_player(inv, list)
	for _, item in pairs(list) do
		inv:add_item("main", item)
	end
end

function crafting.pick_required_item(inv, listname, item, located)
	local count=0  -- returning count of items found and added to located table.
	item = ItemStack(item)
	local itemName = item:get_name()
  local group_stats = crafting.get_group_stats(itemName)
	if group_stats then
		local required = item:get_count()
		-- search stacks in provided inv and list
		for i = 1, inv:get_size(listname) do
			local stack = inv:get_stack(listname, i)
			-- Is it in group?
			local def = minetest.registered_items[stack:get_name()]
      local group = def and def.groups and def.groups[group_stats.name]
			if required > 0 and group and group_stats.correct(group) then
				local found = ItemStack(stack)
				if found:get_count() > required then
					found:set_count(required)
				end
				located[#located + 1] = found
				count = count + 1

				required = required - stack:get_count()
				if required <= 0 then
					break
				end
			end
		end

		if required > 0 and count > 0 then
			-- not enough so delete located items
			for j=1,count do
				located[#located] = nil
			end
			count=0		
		end
	else
		if inv:contains_item(listname, item) then
			located[#located + 1] = item
			count = count + 1
		end
	end
	return count
end


function crafting.parse_where(recipe, items, item_idx, num_added)
	if recipe.where or type(recipe.where) ~= 'string' then
		return nil
	end
	local result = recipe.where_results or recipe.where

	-- @1.material == @2.material
--	local input1,key1,test,input2,key2 = 
--print("where: "..recipe.where)
--print(dump( string.match(recipe.where, "@(%d+)%.(%w+)%s*(.*)%s*@(%d+)%.(%w+)$") ))

end

function crafting.find_required_items(inv, listname, recipe)
	local items = {}
	-- updated to allow passing of a table of listnames
	-- items are taken from inventories in order passed
	-- this converts old use of this function to new use
	if type(listname) ~= 'table' then
		listname = { listname }
	end

--print("Recipe Items: "..dump(recipe.items))
	for i, item in ipairs(recipe.items) do
		local picked = false	-- assume we don't find it
		-- search each of passed lists
		for _,list in ipairs(listname) do
 			-- Conditional input list to process
 			if (type(item) == 'table') then
 				for _, conItem in ipairs(item) do
 					local count = crafting.pick_required_item(inv, list, conItem, items)
 					if count >0 then 
 						picked = true
 						break
 					end
 				end
 			else
				if crafting.pick_required_item(inv, list, item, items) >0 then
					picked = true
				end
 			end
		end
		if not picked then
			return nil -- didn't find
		end
	end
	return items
end

-- IB---
-- IB---
-- IB---						-- check for where clause involving this recipe input item
-- IB---						if recipe.where 
-- IB---print("where: "..recipe.where)
-- IB---print( string.match(recipe.where, "@(%d+)%.(%w+)%s*(.*)%s*@(%d+)%.(%w+)$") )
-- IB---
-- IB---
-- IB---							if crafting.parse_where(recipe,items, i, count) then
-- IB---								picked = true
-- IB---								break
-- IB---							else
-- IB---								items[#items] = nil --delete picked item because where failed
-- IB---							end
-- IB---						else
-- IB---
-- IB---


function crafting.has_required_items(inv, listname, recipe)
	return crafting.find_required_items(inv, listname, recipe) ~= nil
end

function crafting.register_on_craft(func)
	table.insert(crafting.registered_on_crafts, func)
end

function crafting.perform_craft(name, inv, listname, outlistname, recipe)
   local items = crafting.find_required_items(inv, listname, recipe)
--print ("Perform_crafting() "..dump(items))
   if not items then
      return false
   end

	-- updated to allow passing of a table of listnames
	-- items are taken from inventories in order passed
	-- this converts old use of this function to new use
	if type(listname) ~= 'table' then
		listname = { listname }
	end

	-- Take items
	local taken = {}
	for _, item in pairs(items) do
		item = ItemStack(item)
		local count = item:get_count()
		local tcount = 0;
		for _, list in ipairs(listname) do
			local took = inv:remove_item(list, item)
			if took:get_count() > 0 then
				taken[#taken + 1] = took
				tcount = tcount + took:get_count()
				if tcount == count then 
					break -- found so done
				end
			end
		end
		if  tcount ~= count then
			 minetest.log("error", "Unexpected lack of items in inventory")
			 give_all_to_player(inv, taken)
			 return false
		end
	end

   for i=1, #crafting.registered_on_crafts do
      crafting.registered_on_crafts[i](name, recipe)
   end
   -- create item
	local material
	if recipe.material then
		local material_def = ItemStack(taken[recipe.material]):get_definition()
		material = material_def.exile_crafting and material_def.exile_crafting.material
    if not material then -- issue #814
      error("crafting.perform_craft: missing exile_crafting or exile_crafting.material but got material '"
      ..tostring(recipe.material).."' known as in taken: '"..tostring(taken[recipe.material]).."' from '"
      ..material_def.name..";;"..material_def.description.."' to craft '"..recipe.output
      .."'. Crafting commenced by "..tostring(name))
    end
	end


	local make_output = recipe.output
	if recipe.material_output then
		make_output = string.gsub(recipe.material_output, "%%material%%", material)
	end
   local itemstack = ItemStack(make_output)
   local imeta = itemstack:get_meta()
   local idef = itemstack:get_definition()
   local sdesc = itemstack:get_short_description()
   -- Set Creator
   if minetest.get_item_group(itemstack:get_name(), 'craftedby') > 0 then
      imeta:set_string('creator', name)
      -- don't add creator name to sort description for single player
      if not minetest.is_singleplayer() then
		sdesc = name .. "'s " .. sdesc
	  end
	  imeta:set_string('short_description', sdesc)
   end

	-- set material
	if material then
		imeta:set_string('material', material)
		if recipe.tiles_name then
			local image = string.gsub(recipe.tiles_name, '%%material%%', material)
			imeta:set_string('inventory_tiles', image)
		end
		if recipe.real_name then
			local image = string.gsub(recipe.tiles_name, '%%material%%', material)
			imeta:set_string('inventory_tiles', image)
		end

	end

   -- Add Tool Tips to Description

   if idef._tool_tips and idef._tool_tips ~= '' then
      --imeta:set_string('description',sdesc .. idef._tool_tips)

   end
  local items_to_add = {}
  local count = itemstack:get_count()
  -- fix for tools not being added properly (have to manually get the count from the string...)
  if minetest.registered_tools[itemstack:get_name()] and string.match(make_output," ") then
    local temp = make_output:sub(#itemstack:get_name()+1,#make_output):gsub(" ","") -- temporary value (used to get number)
    count = ""
    for i=1,#temp do
      local char = temp:sub(i,i) -- individual char
      if #count > 0 and not tonumber(char) then
        -- we already got a number, we're going too far!
        break
      elseif tonumber(char) then
        count = count..char -- add more numbers
      end
    end
    -- get itemstack count just incase, don't want nil!
    count = tonumber(count) or itemstack:get_count()
  end
  local max_amt = itemstack:get_stack_max() -- use stack's size for iterating
  local subtract_loop = math.ceil(count / max_amt)
  -- crafted stack size divided by its stack max then ceil'd
  -- (so a stack max and a half will not be 1.5 but rather 2)
  for _ = 1, subtract_loop do
    local item = ItemStack(itemstack) -- clone locally
    if count > max_amt then
      item:set_count(max_amt) -- set stack to max
      count = count - max_amt -- lower count by stack max
    else
      item:set_count(count)
    end
    if count > 0 then -- just in case something goes wrong and an itemstack below or equal to 0 in count is made
      items_to_add[#items_to_add + 1] = item
    end
  end
  -- replace system
  if recipe.replace then
    -- iterate over recipe replace array
    for _,replace in pairs(recipe.replace) do
      items_to_add[#items_to_add + 1] = ItemStack(replace) -- replace item
    end
  end
  -- time to iterate through items and add to inventory or ground
  local warn = false
  local player = minetest.get_player_by_name(name)
  local pos = player:get_pos()
  for _,item in pairs(items_to_add) do
    if inv:room_for_item(outlistname, item) then
      inv:add_item(outlistname, item)
    else
      warn = true
      minetest.add_item(vector.new(pos.x,pos.y+1,pos.z), item)
    end
  end
   if warn then minimal.warn_inv_full(player) end
   return true
end

local function to_hex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function crafting.calc_inventory_list_hash(inv, listname)
	local str = ""
	for _, stack in pairs(inv:get_list(listname)) do
		str = str .. stack:get_name() .. stack:get_count()
	end
	return minetest.sha1(to_hex(str))
end
