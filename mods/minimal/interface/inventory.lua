
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

-- The inventory formspec is cached for each player like this:
-- inventoryFS_cache[player_name] = {
--	formspec = {
--		epoch = os.time(),
--		ctype = selected_craft_type -- set by craft_type buttons
--		clevel = craft_type_level	-- set by craft type buttons
--		sInv = selected_inventory	-- set by bag buttons
--		-- The Following are tables of formspec strings
--		-- Set output = "" to force redraw using cashed details 
--		-- to trigger redraw of a section, set the section to nil
--		-- eg) to regenerate the recipes list, set
--		-- cache.recipes = nil, and cache.output = ""
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

local __inventoryFS_cache_timeout = 300 -- five minute cache too much?
local inventoryFS_cache = {}

local function process_button(key,btypes)
	for _,prefix in ipairs(btypes) do
		if key:sub(1, 7) == prefix then
			local num = string.match(key, prefix.."_([0-9]+)")
			if num then
				return prefix, num
			end
		end
	end
	return nil,nil -- button types not found
end



minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= '' then return false; end -- Not our form.

	local player_name = player:get_player_name()
print (player_name .. " --> '" .. formname .. "'")
print (dump(fields)) 
	-- process all fields for button pushes.
	local btn_type
	local btn_id
	for key, value in pairs(fields) do
		btn_type,btn_id = process_button(key,{'iresult','ibelt'})
		if btn_type ~= nil then
			break	-- We found a button
		end
    end
	if btn_type then
		local inv    = player:get_inventory()
		local name   = player:get_player_name()
		local cache = inventoryFS_cache[name]
		if btn_type == 'ibelt' then
			local craft_type = inv:get_list('craft_types')[btn_id]
			local cItem = craft_type:get_name()
			local def = minetest.registered_nodes[cItem] 
				or minetest.registered_tools[cItem] 
				or minetest.registered_items[cItem]
			if def then
				cache.ctype = def._craft_type
				cache.clevel = def._craft_level
				cache.recipes = nil
				cache.output = ""
			end
		elseif btn_type == 'iresult' then
			local recipe = crafting.get_recipe(tonumber(btn_id))
			local ctype = cache.ctype
			local clevel = cache.clevel
			local sInv = cache.sInv
			if not crafting.can_craft(name, ctype, clevel, recipe) then
				minetest.log("error", "[crafting] Player clicked a button they shouldn't have been able to")
				return true
			elseif crafting.perform_craft(name, inv, {"input_items","main"}, "main", recipe) then
				cache.recipes = nil
				cache.output = nil
				inventoryFS_cache[name] = cache
				return true -- crafted
			else
				minetest.chat_send_player(name, "Missing required items!")
				return false
			end
		end
	else
	end
end)

	

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
	local recipesFS = {}
	local ctype = cache.ctype 	-- craft type selected
	local level = cache.clevel	-- level associated with selected craft type
	local recipe_list = recipes_for_player(cache, pInv, player_name,ctype, level)



	-- Add tab header
	local tabs=''
	recipesFS[#recipesFS + 1] = "style_type[item_image_button;border=false]"
	recipesFS[#recipesFS + 1] = 'tabheader[3.2,1;sfinv_nav_tabs;' .. tabs .. ';1;true;false]'
	-- add Scrollable container
	local scroll_max = #recipe_list / 5 
	recipesFS[#recipesFS + 1] = 'scrollbaroptions[max=' .. tonumber(scroll_max) .. ';'
		.. 'smallstep=1;largestep=1'
		.. ']'
	recipesFS[#recipesFS + 1] = 'scrollbar[9.2,1.2;.5,4.6;vertical;recipes_scroll;0]'
	recipesFS[#recipesFS + 1] = 'scroll_container[3.2,1;6,5;recipes_scroll;vertical;1]'
	-- Add recipe buttons in rows of 5 
	local x = 0
	local y = 0
	for i, result in ipairs(recipe_list) do
		-- recipe 
		local recipe_output = result.recipe.output
		local itemname=ItemStack(recipe_output):get_name()
		local item_description = crafting.get_item_description(itemname)

--		local def = minetest.registered_items[rItem] or minetest.registered_nodes[rItem]
		local id = result.recipe.id
		local bg_coords =  tostring(x * 1.2) ..','.. tostring(y * 1.2 + 0.2)
		-- set background image
		local bg_image
		local craftable = result.craftable
		if craftable then
			bg_image = 'crafting_slot_craftable.png'
		else
			bg_image = 'crafting_slot_uncraftable.png'
		end
		recipesFS[#recipesFS +1] = "image[" .. bg_coords .. ";1,1;" .. bg_image .. "]"
		-- Add button image
		local btn_coords = tostring( x* 1.2 + 0.1 ) .. ','..tostring( y * 1.2 + 0.3 )
		recipesFS[#recipesFS + 1] = 'item_image_button['
			.. btn_coords .. ';.8,.8;' 
			.. recipe_output .. ';iresult_' .. id ..';]'
		recipesFS[#recipesFS + 1] = 'tooltip[iresult_' .. id..';'
			.. minetest.formspec_escape(item_description .. "\n")
		for j, item in pairs(result.items) do
             local color = item.have >= item.need and "#6f6" or "#f66"
             local tool_tip ="\n"
                ..  minetest.get_color_escape_sequence(color) 
                ..  crafting.get_item_description(item.name) .. ": "
                ..  item.have .."/".. item.need
             recipesFS[#recipesFS + 1] = minetest.formspec_escape(tool_tip)
         end
         recipesFS[#recipesFS + 1] = minetest.get_color_escape_sequence("#ffffff") .. ']'
		x = x + 1
		if x > 4 then
			x = 0
			y = y + 1
		end
	end
	
	recipesFS[#recipesFS + 1] =	'scroll_container_end[]'
	recipesFS[#recipesFS + 1] =	'field[4.2,6;3,.5;query;;]'
	recipesFS[#recipesFS + 1] =	'button[7.3,6;.6,.5;?;?]'
	cache.recipes = recipesFS
	return recipesFS
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
					.. stack:get_short_description() .. ']'
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
	inventoryFS_cache[player_name].recipes = nil
	-- clear cached output to force redraw for new formspec
	inventoryFS_cache[player_name].output=""
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
	local cache = inventoryFS_cache[player_name] or {
		epoch = now,
		output = "",
		player_name = player_name,	
		sInv = 'main',				--default to main inventory
		ctype = 'crafting_spot',	--default to crafting_spot
		clevel = 1,					--default to crafting level 1
	}
	-- return prepared formspec if we have one and it hasn't timed out
	-- Any updates to the form contents should set cache.output = "" 
	if cache.output ~= "" and  (cache.epoch + __inventoryFS_cache_timeout < now) then
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
	inventoryFS_cache[player_name] = cache
	return output
end




