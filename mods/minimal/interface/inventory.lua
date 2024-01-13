-- The inventory formspec is cached for each player like this:
-- inventory_cache[player_name] = {
--	formspec = {
--		epoch = os.time(),
--		ctype = selected_craft_type -- set by craft_type buttons
--		clevel = craft_type_level	-- set by craft type buttons
--		sInv = selected_inventory	-- set by bag buttons
--		-- The Following are tables of formspec strings; set to nil to force redraw of section
--		-- set output = "" to force redraw of cached formspec.
--		header = {},
--		craft_type = {},
--		craft_items = {},
--  	recipes = {},
--		inventory = {},
--		output = "",
--	}
-- output is cleared if any of the elements is updated to force a redraw
-- each section of the formspec is cached as a table of lines.  If updated,
-- a section should be set to nil and output set to "" to force a redraw.
-- only sections cleared are recreated via make_inventory_formspec

-- Create global default detached "craft_types" inventory
-- Used to populate players craft_types
local ctypes = minetest.create_detached_inventory("craft_types")
ctypes:set_size('main',12) 
ctypes:set_list('main',{
	'tech:crafting_spot',
	'tech:weaving_spot',
	'tech:threshing_spot',
	'tech:grinding_spot',
	'tech:mixing_spot',
})


local __inventory_cache_timeout = 300 -- five minute cache too much?
local inventory_cache = {}

local function recipes_for_player(cache, pInv, player_name, ctype, level)
	local unlocked = crafting.get_unlocked(player_name)
	-- build player items hash
	local item_hash = {}
	-- add input_items inventory
	if pInv:get_size('input_items') > 0 then
		crafting.set_item_hashes_from_list(pInv, 'input_items', item_hash)
	end
	-- add selected inventory
	local selected = cache.sInv or 'main'
	if pInv:get_size(selected) > 0 then
		crafting.set_item_hashes_from_list(pInv, selected, item_hash)
	end
	-- Get all available recipies and mark craftible ones.
	local results =  crafting.get_all(ctype, level, item_hash, unlocked)
	return results
end



-- This needs to be rebuilt every time the craft_type, input_items, or inventory changes
-- but only if there is an open formspec.
-- It is triggered by setting cache.recipes = nil
local function cache_player_recipes(cache, player_name, pInv)
	local recipes = {}
	local ctype = cache.ctype
	local level = cache.clevel
	local recipe_list = recipes_for_player(cache, pInv, player_name,ctype, level)
	local max = #recipe_list / 5

	recipes[#recipes + 1] = 'tabheader[3.2,1;sfinv_nav_tabs;Craft,Mixing;1;true;false]'
	recipes[#recipes + 1] = 'scrollbaroptoins[max=' .. tonumber(max) .. ';'
		.. 'smallstep = 1;largestep=1;'
		.. ']'
	recipes[#recipes + 1] = 'scrollbar[9.2,1.2;.5,4.6;vertical;recipes_scroll;0]'
	recipes[#recipes + 1] = 'scroll_container[3.2,1;6,5;recipes_scroll;vertical;1]'

	-- Add tab header

	-- Add recipe buttons in rows of 6
	local x = 0
	local y = 0
	for i, recipe in ipairs(recipe_list) do
		-- recipe 
		local recipe_output = recipe.recipe.output
		local rItem=ItemStack(recipe_output)
		local def = minetest.registered_items[rItem] or minetest.registered_nodes[rItem]

		local tool_tip = "TOOL TIP"
		if def and def.tool_tip then
			tool_tip=def.tool_tip
		end
		local coords =  tostring(x * 1.2) ..','.. tostring(y * 1.2 + 0.2)
		recipes[#recipes + 1] = 'item_image_button['
			.. coords
			.. ';1,1;' 
			.. recipe_output .. ';result_' .. i ..';]'
		if tool_tip then 
			recipes[#recipes + 1] = 'tooltip[result_' .. i..';'
				.. tool_tip .. ';]'
		end
		x = x + 1
		if x > 4 then
			x = 0
			y = y + 1
		end
	end
	
	recipes[#recipes + 1] =	'scroll_container_end[]'
	recipes[#recipes + 1] =	'field[4.2,6;3,.5;query;;]'
	recipes[#recipes + 1] =	'button[7.3,6;.6,.5;?;?]'
--	recipes[#recipes + 1] =	'button[8.5,6;.6,.5;up;+]'
--	recipes[#recipes + 1] =	'button[9.1,6;.6,.5;down;-]'
	cache.recipes = recipes
	return recipes
end

-- This needs to be rebuilt every time you change the inventory being viewed - so clicking bags
-- This is triggered by setting cache.inventory = nil
local function cache_player_inventory(cache, pInv)
	local selected = cache.sInv or 'main'
	local inventory = {}
	inventory[#inventory + 1] = 'style_type[list;size=;spacing=]'
	inventory[#inventory + 1] = 'list[current_player;' .. selected .. ';.4,6.7;8,2;0]'
	inventory[#inventory + 1] = 'listring[]'
	inventory[#inventory + 1] = 'tabheader[.4,9.8;inventory_tab;Main,Bag1,Bag2,Bag3,Bag4;1;true;false]'

	cache.inventory = inventory
	return inventory
end

-- Shouldn't need to be rebuilt more then once per player per restart
local function cache_player_input_list(cache, pInv)
	local inputs = pInv:get_list('input_items')
	if not inputs or #inputs ~= 16 then
		-- create inputs inventory list and draw formspec for input_itmes
		pInv:set_size('input_items', 16)
	end

	cache.input_list = {
		'container[.4,3.2]',
		'label[.1,0;Input Items]',
--		'box[0,.2;2.5,2.5;black]',
		'style_type[list;size=.5,.5;spacing=.1]',
		'list[current_player;input_items;.1,.3;4,4;0]',
		'container_end[]',
	}
	return cache.input_list
end

-- Shouldn't need to rebuild this more then once per player per restart
-- or when player adds to their craft_types 
-- See adding tools/benches to input_items list
local function cache_player_craft_types(cache, pInv) 
	local selected = cache.ctype or 'crafting_spot' -- default to hand crafting
	local ctypes=pInv:get_list('craft_types')
	if not ctypes then
		-- set player craft_type to global default
		ctypes=minetest.get_inventory({type='detached',name='craft_types'}):get_list('main')
		pInv:set_size('craft_types', 12)
		pInv:set_list('craft_types', ctypes)
	end
	cache.craft_type = {
		'container[.4,.8]',
		'label[0.1,0;Craft Type]',
		'box[0,.2;2.5,1.9;black]',
	}
	local x = 0
	local y = 0
	for i,stack in ipairs(ctypes) do
		local coords = tostring(x * 0.6 + 0.1) ..','.. tostring(y * 0.6 + 0.3) 
		if not stack:is_empty() then
			-- Dipslay item image
			local itemname = stack:get_name()
			cache.craft_type[#cache.craft_type + 1] = 
				'item_image_button[' .. coords .. ';.5,.5;' 
					.. itemname ..';belt_' .. i .. ';]'
			cache.craft_type[#cache.craft_type + 1] = 
				'tooltip[belt_' .. i .. ';'
					.. stack:get_short_description() .. ';]'
		else
			-- display empty space
			cache.craft_type[#cache.craft_type + 1] = 
				'image[' ..coords..';.5,.5;crafting_slot_empty.png]'
		end
		x = x + 1
		if x > 3 then
			x = 0
			y = y + 1
		end
	end
	cache.craft_type[#cache.craft_type + 1] = 'container_end[]'
end


-- Call when the inventory formspec is closed to clear cache
function minimal.close_inventory_formspec(player)
	local player_name = player:get_player_name()
	if not (player_name and player_name ~= "") then
		return nil -- no player name
	end
	-- Assume recipes will need to be redrawn on reopen
	inventory_cache[player_name].recipes = nil
	-- clear cached output to force redraw for new formspec
	inventory_cache[player_name].output=""
end

-- This is the function to call to create or update the formspec.
-- It returns the cache value unless something has updated or it times out
-- updates are triggered by setting cache.output = "" and the section to 
-- redraw is set to nil - eg cache.recipes = nil to redraw recipes list.
function minimal.get_inventory_formspec(player)
	local player_name = player:get_player_name()
	if not (player_name and player_name ~= "") then
		return nil -- no player name
	end
	local now = os.time()
	local cache = inventory_cache[player_name] or {
		epoch = now,
		output = "",
		player_name = player_name,	
		sInv = 'main',				--default to main inventory
		ctype = 'crafting_spot',	--default to crafting_spot
		clevel = 1,					--default to crafting level 1
	}
	-- return prepared formspec if we have one and it hasn't timed out
	-- Any updates to the form contents should set cache.output = "" 
	if cache.output ~= "" and  (cache.epoch + __inventory_cache_timeout < now) then
		return cache.output
	end
	-- add formspec Header
	local output = 
		'formspec_version[5]' ..
		'size[10.5,10]' ..
		'label[.4,6.2;Quantity]' ..
		'dropdown[1.5,6.0;1.4,.4;qty;Single,Stack,Maximum;1;true]'
	-- add Craft Types
	local pInv = player:get_inventory()
	if not cache.craft_type then
		cache_player_craft_types(cache, pInv)
	end
	output = output .. table.concat(cache.craft_type, "")
	-- add Input List
	if not cache.input_list then
		cache_player_input_list(cache,pInv)
	end
	output = output .. table.concat(cache.input_list, "")
	-- add Recipes List
	if not cache.recipes then
		cache_player_recipes(cache,player_name,pInv)
	end
	output = output .. table.concat(cache.recipes, "")
	-- add Inventory List
	if not cache.inventory then
		cache_player_inventory(cache,player)
	end
	output = output .. table.concat(cache.inventory, "")
	-- Save output to cache and update
	cache.output = output
	inventory_cache[player_name] = cache
	return output
end




