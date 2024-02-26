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
}

function crafting.register_type(name, label)
	crafting.recipes[name] = {}
	-- add a label for tabs - default to the name
	crafting.tab_labels[name] = (label or name)
end

function crafting.register_recipe(def)
	assert(def.output, "Output needed in recipe definition")
	assert(def.type,   "Type needed in recipe definition")
	assert(def.items,  "Items needed in recipe definition")

	def.level = def.level or 1
	-- Can be more then one craft station for a recipe
	-- Need to store as a table.
	if type(def.type) == 'string' then
		def.type = { def.type }
	end
	-- Support multiple output items via a serialzed string
	local output = def.output
	if type(def.output) == 'table' then
		output = minetest.serialize(def.output)
	end
        def.id = #crafting.recipes_by_id + 1
	crafting.recipes_by_output[output] = def
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

function crafting.pick_all(inv, item, items, item_hash,line)
	item = ItemStack(item)
	local needed_count = item:get_count()
	local craftable = true
	local available_count = item_hash[item:get_name()] or 0
	if available_count < needed_count then
		craftable = false
	end

	items[#items + 1] = {
		name = item:get_name(),
		have = available_count,
		need = needed_count,
		line = line,
	}
	return craftable
end


function crafting.get_all(ctype, level, item_hash, unlocked)
	assert(crafting.recipes[ctype], "No such craft type!")

	local results = {}
	for _, recipe in pairs(crafting.recipes[ctype]) do
		local craftable = true
		if recipe.level <= level and (recipe.always_known or unlocked[recipe.output]) then
			-- Check all ingredients are available
			local items = {}
			for i, item in pairs(recipe.items) do
				-- Conditional input list to process
				if (type(item) == 'table') then
					local picked = false
					for _, conItem in ipairs(item) do
						if crafting.pick_all(inv, conItem, items, item_hash,i) then
							picked = true
						end
					end
					if not picked then
						craftable = false -- didn't find
					end
				else
					if not crafting.pick_all(inv, item, items, item_hash,i) then
						craftable = false
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
				for groupname, _ in pairs(def.groups) do
					local group = "group:" .. groupname
					item_hash[group] = (item_hash[group] or 0) + stack:get_count()
				end
			end
		end
	end
end

function crafting.get_all_for_player(player, ctype, level)
	local unlocked = crafting.get_unlocked(player:get_player_name())
	-- build player items hash
	local item_hash = {}
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
			if  rec_type == station and recipe.level <= level and
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
	item = ItemStack(item)
	local itemName = item:get_name()
	if itemName:sub(1, 6) == "group:" then
		local groupname = itemName:sub(7, #itemName)
		local required = item:get_count()

		-- Find stacks in group
		for i = 1, inv:get_size(listname) do
			local stack = inv:get_stack(listname, i)

			-- Is it in group?
			local def = minetest.registered_items[stack:get_name()]
			if def and def.groups and def.groups[groupname] then
				stack = ItemStack(stack)
				if stack:get_count() > required then
					stack:set_count(required)
				end
				located[#located + 1] = stack

				required = required - stack:get_count()

				if required == 0 then
					break
				end
			end
		end

		if required > 0 then
			return nil
		end
	else
		if inv:contains_item(listname, item) then
			located[#located + 1] = item
		else
			return nil
		end
	end
	return located
end

function crafting.find_required_items(inv, listname, recipe)
	local items = {}
	-- updated to allow passing of a table of listnames
	-- items are taken from inventories in order passed
	-- this converts old use of this function to new use
	if type(listname) ~= 'table' then
		listname = { listname }
	end
	for _, item in pairs(recipe.items) do
		local picked = false	-- assume we don't find it
		-- search each of passed lists
		for _,list in ipairs(listname) do
			-- Conditional input list to process
			if (type(item) == 'table') then
				for _, conItem in ipairs(item) do
					if crafting.pick_required_item(inv, list, conItem, items) ~= nil then
						picked = true
						break
					end
				end
			else
print(dump(item))
				if crafting.pick_required_item(inv, list, item, items) ~= nil then
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

function crafting.has_required_items(inv, listname, recipe)
	return crafting.find_required_items(inv, listname, recipe) ~= nil
end

function crafting.register_on_craft(func)
	table.insert(crafting.registered_on_crafts, func)
end

function crafting.perform_craft(name, inv, listname, outlistname, recipe)
   local items = crafting.find_required_items(inv, listname, recipe)
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
		for _, list in ipairs(listname) do
			local took = inv:remove_item(list, item)
			taken[#taken + 1] = took
			item:set_count(item:get_count() - took:get_count())
			if not item:get_count() then
				break
			end
		end

		if item:get_count() ~= 0 then
			 minetest.log("error", "Unexpected lack of items in inventory")
			 give_all_to_player(inv, taken)
			 return false
		end
	end

   for i=1, #crafting.registered_on_crafts do
      crafting.registered_on_crafts[i](name, recipe)
   end
   -- create item
   local itemstack = ItemStack(recipe.output)
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

   -- Add Tool Tips to Description

   if idef._tool_tips and idef._tool_tips ~= '' then
      imeta:set_string('description',sdesc .. idef._tool_tips)
	--  minetest.override_item(name, { description = newdesc,
    --                        _orig_desc = orig_desc })

   end
   local max_amt = itemstack:get_stack_max()
   local count = itemstack:get_count() -- use stack's size for iterating
   local subtract_loop = math.ceil(count / max_amt)
   -- crafted stack size divided by its stack max then ceil'd
   --  (so a stack max and a half will not be 1.5 but rather 2)

   -- Loop time
   local warn = false
   local player = minetest.get_player_by_name(name)
   for _ = 1, subtract_loop, 1 do
      -- loop through the amount of times stack is over its max, if 1 then
      --  only run code once
      if (count > max_amt) then
	 itemstack:set_count(max_amt) -- set stack to max
	 count = count - max_amt -- lower count by stack max
      elseif (count > 0) then -- if no modifications necessary then just set it to count
	 itemstack:set_count(count)
      end

      -- add output
      if (count > 0) then -- just in case something goes wrong and an itemstack below or equal to 0 in count is made
	 if inv:room_for_item(outlistname, itemstack) then
	    inv:add_item(outlistname, itemstack)
	 else
	    local pos = player:get_pos()
	    warn = true
	    minetest.add_item(vector.new(pos.x,pos.y+1,pos.z), itemstack)
	 end
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
