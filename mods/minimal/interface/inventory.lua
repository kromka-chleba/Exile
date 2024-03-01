-- This mod adds a "exile_crafting" key to node definitions.
--		exile_crafting = {
--			-- name of craft type, or table of craft types.  A table produces tabs of recipes.
--			-- Must be registered with crafting.register_type().
--			craft_types = {'hand','hand_mixing'}
--			-- craft_types = 'craft_spot'		-- for single tab
--			craft_level = 1						-- crafting level of node/item
--		}

--   * Items that have this key will auto transfer to the craft_type inventory if moved into the
--	   input_items inventory.
--


-- Create global default detached "craft_types" inventory
-- Used to populate players craft_types
local ctypes = minetest.create_detached_inventory("craft_types")
ctypes:set_size('main',12)
ctypes:set_list('main',{
	'tech:crafting_spot',
	'tech:weaving_frame',
	'tech:threshing_spot',
	'tech:grinding_stone_granite',
})

-- The inventory formspec is cached for each player like this:
-- inventoryFS_cache[player_name] = {
--		epoch  = os.time(),					-- Used to expire cache
--		sItem  = selected_craft_type_item -- set by craft_type item buttons defaults - to first
--		sTab   = selected_craft_tab 	-- index of selected tab in ctypes - default = 1
--		sLevel = selected craft_type_level	-- set by craft type item selected
--		sScroll = selected scroll level -- needed to draw scroll container
--		cTabs = table_of_craftItem_tabs	-- set by def.exile_crafting.craft_type.
--		sInv = selected_inventory	-- set by bag buttons
--		-- The Following are tables of formspec strings
--		-- Set output = "" to force redraw using cashed details
--		-- to trigger redraw of a section, set the section to nil
--		-- eg) to regenerate the recipes list, set
--		-- cache.recipesFS = nil, and cache.output = ""
--		craft_typeFS = {},
--		craft_itemsFS = {},
--  	recipesFS = {},
--		inventoryFS = {},
--		output = "",
--	}
-- output is cleared if any of the elements is updated to force a redraw
-- each section of the formspec is cached as string.  If updated,
-- a section should be set to nil and output set to "" to force a redraw.
-- only sections cleared are recreated via make_inventory_formspec

local __inventoryFS_cache_timeout = 90 -- seconds between redraws
local inventoryFS_cache = {}



local function debug_keys(table)
	local output=""
	for k,v in pairs(table) do
		output = output .. v .. ','
	end
	return output
end

local function debug_cache(table)
	local output=""
	for k,v in pairs(table) do
		if (string.match(k, '.*FS$') or k == 'output') then
			output = output .. k
		else
			if type(v) == 'table' then
				v = debug_keys(v)
			end
			output = output .. k .. ' = ' .. v
		end
		output = output ..', '
	end
	return output
end

local function process_button(key,btypes)
	for _,prefix in ipairs(btypes) do
		if key:sub(1, #prefix) == prefix then
			local num = string.match(key, prefix.."_([0-9]+)")
			if num then
				return prefix, num
			end
		end
	end
	return nil,nil -- button types not found
end


--
local function load_craft_types(inv, craft_item)
	local cItems = inv:get_list('craft_types')
	if not cItems or inv:is_empty('craft_types') then
		-- set player craft_type to global default
		cItems=minetest.get_inventory({type='detached',name='craft_types'}):get_list('main')
		inv:set_size('craft_types', 12)
		inv:set_list('craft_types', cItems)
	end
	if craft_item then
		inv:add_item('craft_types', craft_item)
	end
	return inv:get_list('craft_types')
end

-- Set default values for cache. Used if craft type Item is changed and when formspec first opened
local function set_cache(player_name,inv,sItemID)
	local cache = inventoryFS_cache[player_name]
	if not cache or cache == 'closed' then
		cache = {}
	end
	-- clear old cache values
	cache.epoch = os.time()
	cache.craft_typesFS = nil
	cache.input_itemsFS = nil
	cache.recipesFS = nil
	cache.output = ""
	cache.sInv = cache.sInv or 'main'	-- XXX need to make sure selected inv exists.

	local cItems = load_craft_types(inv)
	-- Default to the first craft_types inventory item if not provided
	sItemID = sItemID or 1
	local stack = cItems[sItemID]
	local sItem = stack:get_name()
	if cache.sItem ~= sItem then
		cache.sItem = stack:get_name()
		cache.sTab = 1 -- default to first tab
		cache.sScroll = 0 -- reset scrollbar to top
	end
	local def = minetest.registered_nodes[cache.sItem]
		or minetest.registered_tools[cache.sItem]
		or minetest.registered_items[cache.sItem]
	if def and def.exile_crafting then
		local tabs = def.exile_crafting.craft_types
		if not tabs then
			error('no tabs defined for '.. cache.sItem)
		end
		if type(tabs) ~= 'table' then
			tabs = { tabs }
		end
		cache.cTabs = tabs
		cache.sLevel = def.exile_crafting.craft_level
	else
		print('ERROR: Missing exile_crafting definition for '..sItem)
	end

	inventoryFS_cache[player_name]=cache
	return cache
end

local function process_receive_fields(player, formname, fields)
--	if formname ~= '' or formname ~= 'exile:crafting' then return false; end -- Not our form.
	local player_name = player:get_player_name()
	local inv = player:get_inventory()
	local cache = inventoryFS_cache[player_name]
	if not cache or cache == 'closed' then
		cache = set_cache(player_name,inv)
	end
	local done = false	-- flag to skip processing buttons and skip to saving changes.
	-- Process quit
	if fields.quit then
		minimal.close_inventory_formspec(player)
		return true -- cache updated in close
	end
	-- process scrollbar
	if fields.recipes_scroll then
		local value = fields.recipes_scroll
		local scroll = tonumber(string.match(value, "CHG:([0-9]+)"))
		if scroll and scroll ~= cache.sScroll then
			cache.sScroll = scroll
			cache.recipesFS = nil
			cache.output = ""
			done = true
		else
			scroll = tonumber(string.match(value, "VAL:([0-9]+)"))
			if scroll and scroll ~= cache.sScroll then
				cache.sScroll = scroll
				cache.recipesFS = nil
				cache.output = ""
				done = false -- VAL: scrollbar responses produced on button pushes
			end
		end
	end
	-- process craft tabs.
	if fields.sCraftTab then
		cache.sTab = tonumber(fields.sCraftTab)
		cache.sScroll = 0
		cache.recipesFS = nil
		cache.output = ""

		crafting.sort_order_by_player[player_name] = nil
		done = true
	end

	if not done then
		-- process all fields for button pushes.
		local btn_type
		local btn_id
		for btn, value in pairs(fields) do
			btn_type,btn_id = process_button(btn,{'sResult','sCraftType','sInv'})
			if btn_type ~= nil then
				break	-- We found a button
			end
		end

		if btn_type then
			if btn_type == 'sCraftType' then
				btn_id = tonumber(btn_id)
				cache = set_cache(player_name,inv,btn_id)
				crafting.sort_order_by_player[player_name] = nil
			elseif btn_type == 'sInv' then
				cache.sInv = btn_id -- Inventory name
			elseif btn_type == 'sResult' then
			   local recipe = table.copy(crafting.get_recipe(tonumber(btn_id)))
print(dump(recipe))
			   local ctype = cache.cTabs[cache.sTab]
			   local sLevel = cache.sLevel
			   local sInv = cache.sInv
			   local qty = tonumber(fields.qty)
			   if not qty then qty = 1 end
			   if qty > 1 then -- more then single requested
			      local oItem = ItemStack(recipe.output)
			      local oName = oItem:get_name()
			      local oCount = oItem:get_count() or 1
			      local max_count = 0
			      local item_hash = cache.item_hash
			      for i,input in ipairs(recipe.items) do
				 local iItem = ItemStack(input)
				 local iName = iItem:get_name()
				 local iNeed = iItem:get_count()
				 local iHave = item_hash[iName] or 0
				 local max = math.floor(iHave/iNeed)
				 if max_count < max then
				    max_count = max
				 end
			      end
			      if qty == 2 then -- stack requested
				 local def = minetest.registered_nodes[oName] or minetest.registered_craftitems[oName]
				    or minetest.registered_tools[oName]
				 local stack_count = def.stack_max or 1
				 if max_count > stack_count then
				    max_count = stack_count
				 end
			      end
			      -- set output to max_count
			      recipe.output = oName .." "..max_count * oCount
			      -- set input to values for max_count
			      for i,input in ipairs(recipe.items) do
				 local iItem = ItemStack(input)
				 local iName = iItem:get_name()
				 local iNeed = iItem:get_count()
				 recipe.items[i] = iName .." ".. iNeed * max_count
			      end
			   end

			   if not crafting.can_craft(player_name, ctype, sLevel, recipe) then
			      minetest.log("error", "[inventoryFS] Player clicked a button they shouldn't have been able to")
			      return true
			   elseif crafting.perform_craft(player_name, inv, {"input_items",sInv}, sInv, recipe) then
			      cache.recipesFS = nil
			      cache.output = ""
			      inventoryFS_cache[player_name] = cache
			      return true -- crafted
			   else
			      minetest.chat_send_player(player_name, "Missing required items!")
			      return true -- failed but we handled it
			   end
			end
			-- any button pushes require recipes to be redrawn
			cache.output = ""
			cache.recipesFS = nil
		else
		end
	end
	inventoryFS_cache[player_name] = cache
	return true
end

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
	-- save item_hash to cache
	cache.item_hash = item_hash
	-- Get all available recipies and mark craftible ones.
	local results =  crafting.get_all(ctype, level, item_hash, unlocked)
	return results
end

-- This needs to be rebuilt every time the craft_type, craft_tab, input_items,
-- or selected inventory changes
-- It is triggered by setting cache.recipesFS = nil
local function cache_player_recipes(cache, player_name, pInv)
	local recipesFS = {}
	local sItem = cache.sItem 	-- craft type Item selected
	local sTab = cache.sTab		-- selected craft type tab
	local sLevel = cache.sLevel	-- level associated with selected craft type
	local cTabs = cache.cTabs	-- Crafting tabs to display
	local sScroll = cache.sScroll or 0 -- default to 1 for top of scroll
	local recipe_list = recipes_for_player(cache, pInv, player_name,cTabs[sTab], sLevel)
	-- keep a sort hash so order doesn't change while crafting things
	local sortHash = crafting.sort_order_by_player[player_name]
	if not sortHash or not sortHash.ctype then 
		sortHash = {
			ctype = sItem,
			ctab = sTab,
			hash = {},
		}
	else
		if sortHash.ctype ~= sItem or sortHash.ctab ~= sTab then
			sortHash.ctype = sItem
			sortHash.ctab = sTab
			sortHash.hash = {}
		end
	end
	local sorted = {}
	local not_craftable = {}
	if #sortHash.hash > 0 then
		for _,result in ipairs(recipe_list) do
			local id = tonumber(result.recipe.id)
			local order = sortHash.hash[id]
			if not order then 
				print('no order: '..dump(result))
			else
				sorted[order] = result
			end
		end
	else
		-- sort craftable recipes to top of list
		for _,result in ipairs(recipe_list) do
			local id = result.recipe.id
			if result.craftable then
				sorted[#sorted+1] = result
				sortHash.hash[id] = #sorted
			else
				not_craftable[#not_craftable+1] = result
			end
		end
		for _,result in ipairs(not_craftable) do
			sorted[#sorted+1] = result
			local id = result.recipe.id
			sortHash.hash[id] = #sorted
		end
		--save sort hash
		crafting.sort_order_by_player[player_name] = sortHash
	end
	-- Add tab header
	local tabs = ""
	for i=1,#cTabs do
		if i > 1 then
			tabs = tabs .. ',' -- add comma after first
		end
		tabs = tabs .. crafting.tab_labels[cTabs[i]] or cTabs[i]
	end
	recipesFS[#recipesFS + 1] = "style_type[item_image_button;border=false]"
	recipesFS[#recipesFS + 1] = 'tabheader[3.2,1;sCraftTab;' .. tabs .. ';'
		.. sTab .. ';true;false]'
	-- add Scrollable container
	local columns = 6 -- can show 6 items accross without scrollbar
	if #recipe_list > 24 then
		columns = 5
		local scroll_max = math.ceil(#recipe_list / 5 )
		recipesFS[#recipesFS + 1] = 'scrollbaroptions[max=' .. tonumber(scroll_max) .. ';'
			.. 'smallstep=1;largestep=1;thumbsize=1]'
		recipesFS[#recipesFS + 1] = 'scrollbar[9.2,1.2;.5,4.6;vertical;recipes_scroll;'
			.. sScroll .. ']'
	end
	recipesFS[#recipesFS + 1] = 'scroll_container[3.2,1;'..tostring(columns + 1)..',5;recipes_scroll;vertical;1]'
	-- Add recipe buttons in columns of 5 or 6
	local x = 0
	local y = 0
	for i, result in ipairs(sorted) do
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
			.. recipe_output .. ';sResult_' .. id ..';]'
		recipesFS[#recipesFS + 1] = 'tooltip[sResult_' .. id..';'
			.. minetest.formspec_escape(item_description .. "\n")
		for _, row in ipairs(result.items) do
			local tool_tip ="\n"
			for _, item in ipairs(row) do
				local color = item.have >= item.need and "#6f6" or "#f66"
				tool_tip = tool_tip
					..  minetest.get_color_escape_sequence(color)
					..  crafting.get_item_description(item.name) .. ": "
					..  item.have .."/".. item.need .." "
			end
			recipesFS[#recipesFS + 1] = minetest.formspec_escape(tool_tip)
		end
		recipesFS[#recipesFS + 1] = minetest.get_color_escape_sequence("#ffffff") .. ']'
		x = x + 1
		if x >= columns  then
			x = 0
			y = y + 1
		end
	end

	recipesFS[#recipesFS + 1] =	'scroll_container_end[]'
	recipesFS[#recipesFS + 1] =	'field_close_on_enter[query;false]'
	recipesFS[#recipesFS + 1] =	'field[4.2,6;3,.5;query;;]'
	recipesFS[#recipesFS + 1] =	'button[7.3,6;.6,.5;?;?]'
	cache.recipesFS = table.concat(recipesFS, "")
	cache.output = ""
	return cache
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

	cache.inventoryFS = table.concat(inventory, "");
	cache.output = ""
	return cache
end

-- Shouldn't need to be rebuilt more then once per player per restart
local function cache_player_input_list(cache, pInv)
	local inputs = pInv:get_list('input_items')
	if not inputs or #inputs ~= 16 then
		-- create inputs inventory list and draw formspec for input_itmes
		pInv:set_size('input_items', 16)
	end

	local input_listFS = {
		'container[.4,3.2]',
		'label[.1,0;Input Items]',
--		'box[0,.2;2.5,2.5;black]',
		'style_type[list;size=.5,.5;spacing=.1]',
		'list[current_player;input_items;.1,.3;4,4;0]',
		'container_end[]',
	}
	cache.input_listFS = table.concat(input_listFS, "")
	cache.output = ""
	return cache
end

-- Shouldn't need to rebuild this more then once per player per restart
-- or when player adds to their craft_types
-- See adding tools/benches to input_items list
local function cache_player_craft_types(cache, pInv)
	local selected = cache.sItem or 'crafting_spot' -- default to hand crafting
	local cItems = load_craft_types(pInv)
	local craft_typeFS = {
		'container[.4,.8]',
		'label[0.0,0;Craft Type]',
		'box[0,.2;2.5,1.9;black]',
	}
	local x = 0
	local y = 0
	for i,stack in ipairs(cItems) do
		local coords = tostring(x * 0.6 + 0.1) ..','.. tostring(y * 0.6 + 0.3)
		if not stack:is_empty() then
			-- Dipslay item image
			local itemname = stack:get_name()
			craft_typeFS[#craft_typeFS + 1] =
				'item_image_button[' .. coords .. ';.5,.5;'
					.. itemname ..';sCraftType_' .. i .. ';]'
			craft_typeFS[#craft_typeFS + 1] =
				'tooltip[sCraftType_' .. i .. ';'
					.. stack:get_short_description() .. ']'
		else
			-- display empty space
			craft_typeFS[#craft_typeFS + 1] =
				'image[' ..coords..';.5,.5;crafting_slot_empty.png]'
		end
		x = x + 1
		if x > 3 then
			x = 0
			y = y + 1
		end
	end
	craft_typeFS[#craft_typeFS + 1] = 'container_end[]'
	cache.craft_typeFS=table.concat(craft_typeFS,"");
	cache.output = ""
	return cache
end

-- Call when the inventory formspec is closed to clear cache
function minimal.close_inventory_formspec(player)
	local player_name = player:get_player_name()
	if not (player_name and player_name ~= "") then
		return nil -- no player name
	end
	-- Assume recipes will need to be redrawn on reopen
--	inventoryFS_cache[player_name].recipesFS = nil
--	inventoryFS_cache[player_name].craft_typesFS = nil
	-- clear cached output to force redraw for new formspec
--	inventoryFS_cache[player_name].output=""

	-- Delete sorted items cache
	crafting.sort_order_by_player[player_name] = nil

	-- Delete Cache
	local pInv = player:get_inventory()

	-- Return Items in input_items list to player
	if not pInv:is_empty('input_items') then
		for i=1, pInv:get_size('input_items') do
			local stack = pInv:get_stack('input_items', i)
			if not stack:is_empty() then
				-- Try to add to main inventory
				if pInv:room_for_item('main', stack) then
					stack = pInv:add_item('main', stack)
				end
				-- Drop item if no room in inventory
				if not stack:is_empty() then
					minetest.item_drop(stack, player, player:get_pos())
				end
				-- Set stack to empty stack in input_items inventory
				pInv:set_stack('input_items',i,ItemStack(''))
			end
		end
	end
	-- Empty craft_type items
	if not pInv:is_empty('craft_types') then
		for i=1, pInv:get_size('craft_types') do
			local empty = ItemStack("")
			pInv:set_stack('craft_types', i, empty)
		end
		-- Return items to player.
		-- copies of items added will be added to
		-- the inventory list 'craft_items_return'
		-- they need to be returned here.
	end
	-- delete craft_types list
	pInv:set_size('craft_types',0)
end

function minimal.register_inventory_sfinv()
	if minetest.global_exists("sfinv") then
		local homepage = sfinv.get_homepage_name() -- get name of homepage
		sfinv.register_page(homepage, {
			title = 'Crafting',
			get = function(self, player, context)
				local formspec = minimal.make_inventory_formspec(player,context)
				local options = {
					'formspec_version[5]',	-- hacking in formspec_version before size[]
					'size[10.5,10]',
				}
				local output = sfinv.make_formspec(
					player, context, formspec, false, table.concat(options, ""))
				return output
			end,
			on_player_receive_fields = function(self, player, context, fields)
				process_receive_fields(player, "", fields)
				sfinv.set_player_inventory_formspec(player, context)
			end,
			on_enter = function(self, player, context)
				local player_name = player:get_player_name()
				crafting.sort_order_by_player[player_name] = nil
			end,
			on_leave = function(self, player, context)
				local player_name = player:get_player_name()
				crafting.sort_order_by_player[player_name] = nil
			end,
--			on_enter = function(self, player, context)
--				local player_name = player:get_player_name()
--				inventoryFS_cache[player_name].recipesFS=nil
--				inventoryFS_cache[player_name].output=""
--				sfinv.set_player_inventory_formspec(player,context)
--			end
		})
	end
end

-- This is the function to call to create or update the formspec.
-- It returns the cache value unless something has updated or it times out
-- updates are triggered by setting cache.output = "" and the section to
-- redraw is set to nil - eg cache.recipesFS = nil to redraw recipes list.
function minimal.make_inventory_formspec(player,context)
	local player_name = player:get_player_name()

	local pInv = player:get_inventory()
	if not (player_name and player_name ~= "") then
		return nil -- no player name
	end
	local cache = inventoryFS_cache[player_name]
	-- context exists for inventory formspec only
	if not context and cache == 'closed' then
		return nil
	end
	-- return prepared formspec if we have one and it hasn't timed out
	-- Any updates to the form contents must set cache.output = "" to bypass
	if not cache or cache == 'closed' then
		cache = set_cache(player_name,pInv)
	end
--IB-test	if cache and cache.output and cache.output ~= "" then
--IB-test		if os.time() > cache.epoch + __inventoryFS_cache_timeout then
--IB-test			inventoryFS_cache[player_name].epoch=os.time()
--IB-test		else
--IB-test			return cache.output
--IB-test		end
--IB-test	end
	--reset epoch and draw formspec from cached values unless cleared
	cache.epoch = os.time()
	local output =
		'label[.4,6.2;Quantity]' ..
		'dropdown[1.5,6.0;1.4,.4;qty;Single,Stack,Maximum;1;true]'
	-- add Craft Types
--	if not cache.craft_typeFS then
		cache = cache_player_craft_types(cache, pInv)
--	end
	output = output .. cache.craft_typeFS
	-- add Input List
--	if not cache.input_listFS then
		cache = cache_player_input_list(cache,pInv)
--	end
	output = output .. cache.input_listFS
	-- add Recipes List
--	if not cache.recipesFS then
		cache = cache_player_recipes(cache,player_name,pInv)
--	end
	output = output .. cache.recipesFS
	-- add Inventory List
--	if not cache.inventoryFS then
		cache = cache_player_inventory(cache,player)
--	end
	output = output .. cache.inventoryFS
	-- Save output to cache and update
	cache.output = output
	inventoryFS_cache[player_name] = cache
	return output
end

minimal.register_inventory_sfinv()
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= 'exile:crafting' then return false; end -- Not our form.

	local player_name = player:get_player_name()
	if fields.quit then
		minimal.close_inventory_formspec(player)
		inventoryFS_cache[player_name] = 'closed'
		return true -- cache updated in close
	end

	if process_receive_fields(player, formname, fields) then
		local formspec = minimal.make_inventory_formspec(player)
		if formspec and formspec ~= "" then
			formspec = 'formspec_version[5]size[10.5,10]' .. formspec
			minetest.show_formspec(player_name,'exile:crafting',formspec)
		end
	end
end)

function minimal.crafting_item_on_rightclick(pos,node,clicker,itemstack,pointed_thing)
	local craft_item = ItemStack(node.name)
	local player_name = clicker:get_player_name()
	local pInv = clicker:get_inventory()
	local cItems = load_craft_types(pInv, craft_item)
	-- Set Selected item index
	local sItemID = 0
	for i,stack in ipairs(cItems) do
		if stack:get_name() == node.name then
			sItemID = i
		end
	end
	local cache = {
		sItem = node.name,
		sItemID = sItemID,
		sTab = 1,
		sInv = 'main',
		output = '',
	}
	inventoryFS_cache[player_name] = cache
	set_cache(player_name, pInv, sItemID)
	local formspec = 'formspec_version[5]size[10.5,10]'..minimal.make_inventory_formspec(clicker)
	minetest.show_formspec(player_name,'exile:crafting',formspec)
	return itemstack
end
