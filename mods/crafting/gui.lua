-- Crafting Mod - semi-realistic crafting in minetest
-- Copyright (C) 2018 rubenwardy <rw@rubenwardy.com>
-- Copyright (C) 2022 Jan Wielkiewicz <tona_kosmicznego_smiecia@interia.pl>
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

local S = minetest.get_translator("crafting")

function crafting.get_item_description(name, short)
	if name:sub(1, 6) == "group:" then
		local group = name:sub(7, #name):gsub("%_", " ")
		return S("Any " .. group)
	else
		local def = minetest.registered_items[name] or {}
		return (short and def._orig_desc or nil )
		   or def.description or name
	end
end
function crafting.get_short_description(name)
   return crafting.get_item_description(name, true)
end

local function sanitize(badstring)
   local disallowed = { "\\", "{", "}",
			--lua magic characters
			"%(", "%)", "%[", "%]", "%.", "%$",
			"%^", "%%", "%+", "%-", "%*", "%?"  }
   badstring:trim():lower()
   for i in ipairs(disallowed) do
      badstring = badstring:gsub(disallowed[i],"")
   end
   return badstring
end

function crafting.result_select_on_receive_results(player, type, level, context, fields)
	-- Was a tab selected?
	if fields.crafting_nav_tabs then
		local tid = tonumber(fields.crafting_nav_tabs)
		if tid and tid > 0 then
			context.selected_tab = tid
			--Tab selelected change formspec
			--XXX
			--local tab_name = context.nav[tid]
			--local tab = crafting.tab[id]
			--if id and page then
		--		sfinv.set_page(player, id)
		--	end
		end
		return true
	elseif fields.prev then
		context.crafting_page = (context.crafting_page or 1) - 1
		return true
	elseif fields.next then
		context.crafting_page = (context.crafting_page or 1) + 1
		return true
	elseif fields.search or fields.key_enter_field == "query" then
		context.crafting_query = sanitize(fields.query)
		context.crafting_page  = 1
		if context.crafting_query == "" then
			context.crafting_query = nil
		end
		return true
	end

	for key, value in pairs(fields) do
		if key:sub(1, 7) == "result_" then
			local num = string.match(key, "result_([0-9]+)")
			if num then
				local inv    = player:get_inventory()
				local recipe = crafting.get_recipe(tonumber(num))
				local name   = player:get_player_name()
				if not crafting.can_craft(name, type, level, recipe) then
					minetest.log("error", "[crafting] Player clicked a button they shouldn't have been able to")
					return true
				elseif crafting.perform_craft(name, inv, "main", "main", recipe) then
					return true -- crafted
				else
					minetest.chat_send_player(name, S("Missing required items!"))
					return false
				end
			end
		end
	end
end

local node_fs_context = {}
local node_serial = 0
-- table of formname tabs and tab labels for tabheader by formname
local formname_tabs = {
	-- types = table of crafting types to make tabs
	-- labels = label to use on the tabs
}

local function make_on_show_function(ctype, level, inv_size, context)
	node_serial = node_serial + 1
	local formname = "crafting:node_" .. node_serial

	-- type can be a list of crafting types to appear as tabs
	if type(ctype) == 'table' then
		formname_tabs[formname] = {}
		formname_tabs[formname].types = ctype
	end

	local function show(player, context)
		local types=ctype
		local level = context.level
		local craft_type = ctype
		local tab_labels = nil
		local formspec_tabs = ""
		local selected_tab = context.selected_tab or 1
		if formname_tabs[formname] then
			types = formname_tabs[formname].types
			tab_labels = formname_tabs[formname].labels
			if not types[selected_tab] then
				selected_tab = 1 -- tab doesn't exist most be old context
			end
			context.selected_tab = selected_tab
			-- Generate and save tab labels
			if not tab_labels then
				tab_labels = ""
				for _, tab in ipairs(types) do
					local label = crafting.tab_labels[tab] or tab -- default to using tab name as label
						tab_labels = tab_labels..label..','
				end
				tab_labels = tab_labels:sub(1, -2) -- remove last ,
				formname_tabs[formname].labels = tab_labels
			end
			formname_tabs[formname].labels = tab_labels
			if formname_tabs[formname].types[selected_tab] then
				craft_type = formname_tabs[formname].types[selected_tab]
			end
		end
		if tab_labels and tab_labels ~= "" then
			formspec_tabs = "tabheader[0,0;crafting_nav_tabs;" .. tab_labels ..
				";" .. selected_tab .. ";true;false]"
		end

		local formspec = "size[" .. inv_size.x  .. "," .. (inv_size.y + 3.6) .."]"
				.. formspec_tabs
				.. "list[current_player;main;0," .. (inv_size.y + 1.7) ..";8,1;]"
				.. "list[current_player;main;0," .. (inv_size.y + 2.85) ..";8,3;8]"
				.. crafting.make_result_selector(player, craft_type, level, inv_size, context)
		minetest.show_formspec(player:get_player_name(), formname, formspec)
	end
	minetest.register_on_player_receive_fields(function(player, _formname, fields)
		if formname ~= _formname then
			return
		end

		local context = node_fs_context[player:get_player_name()]
		if not context then
			return false
		end

		if crafting.result_select_on_receive_results(player, ctype, level, context, fields) then
			show(player, context)
		end
		return true
	end)
	return show
end


function crafting.make_on_rightclick(type, level, inv_size)
	local show = make_on_show_function(type, level, inv_size)
	return function(pos, node, player)
		local meta = pos and minetest.get_meta(pos)
		local name = player:get_player_name()
		local context = node_fs_context[name] or {}
		if context.type ~= type then context = {} end
		node_fs_context[name] = context
		context.pos   = vector.new(pos)
		context.type  = type
		context.level = level
		context.creator = (meta and meta:get_string('creator')) or name
		context.tab = 1

		show(player, context)
	end
end

function crafting.make_on_place(type, level, inv_size)
	local show = make_on_show_function(type, level, inv_size)
	return function(itemstack, placer, pointed_thing)
		local pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
		local pt_node=minetest.get_node(pt_pos)
		if pt_node and  minetest.registered_nodes[pt_node.name].on_rightclick then
                    local nodedef = minetest.registered_nodes[pt_node.name]
                    local on_rightclick = nodedef.on_rightclick(pt_pos,pt_node,placer,itemstack,pointed_thing)
                    if on_rightclick then
                        return on_rightclick
                    else
                        -- can't access on_rightclick because the node belongs to another player
                        return itemstack
                    end
		end
		local meta = itemstack:get_meta()
		local name = placer:get_player_name()
		local context = node_fs_context[name] or {}
		node_fs_context[name] = context
		context.pos   = vector.new(pt_pos)
		context.type  = type
		context.level = level
		context.creator = meta:get_string('creator')
		show(placer, context)
	end
end

