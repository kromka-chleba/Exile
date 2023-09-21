-- Based on 4itemnames mod by 4aiman

local item_names = {} -- [player_name] = { hud, dtime, itemname }
local dlimit = 3  -- HUD element will be hidden after this many seconds
local air_hud_mod = minetest.get_modpath("4air")
local hud_mod = minetest.get_modpath("hud")
local hudbars_mod = minetest.get_modpath("hudbars")

local function set_hud(player)
	local player_name = player:get_player_name()
	local off = {x=0, y=-75}
	if air_hud_mod or hud_mod then
		off.y = off.y - 20
	elseif hudbars_mod then
		off.y = off.y + 13
	end
	item_names[player_name] = {
		hud = player:hud_add({
			hud_elem_type = "text",
			position = {x=0.5, y=1},
			offset = off,
			alignment = {x=0, y=0},
			number = 0xFFFFFF,
			text = "",
		}),
		dtime = dlimit,
		index = 1,
		itemname = ""
	}
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0, set_hud, player)
end)

minetest.register_on_leaveplayer(function(player)
	item_names[player:get_player_name()] = nil
end)

local function get_use_string(def)
   -- Figure out what the item is good for, add UI hints accordingly
   local desc = ""
   if def.name == "" then return "" end
   if def.on_use or def.tool_capabilities then
      desc = desc.."^"
   end
   if def._on_use_item
      or def.groups.edible or def.name == "tech:soup" then
      if desc ~= ""  then desc = desc.." / " end
      desc = desc.. "◊"
   end
   if def.on_secondary_use then -- on_use is set for all sorts of things?
      if desc ~= ""  then desc = desc.." / " end
      desc = desc.. "v"
   end
   if desc ~= "" then
      desc = " ( "..desc.." )"
   end
   return desc
end

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local data = item_names[pname]
		if not data or not data.hud then
			data = {} -- Update on next step
			set_hud(player)
		end

		local index = player:get_wield_index()
		local stack = player:get_wielded_item()
		local itemname = stack:get_name()

		if data.hud and data.dtime < dlimit then
			data.dtime = data.dtime + dtime
			if data.dtime > dlimit then
				player:hud_change(data.hud, 'text', "")
			end
		end

		if data.hud and (itemname ~= data.itemname or index ~= data.index) then
			data.itemname = itemname
			data.index = index
			data.dtime = 0

			local desc = stack:get_short_description() or itemname
			local def = minetest.registered_items[itemname]
			if not def then
			   minetest.log("action", pname.." wielded an invalid"..
					" object, "..itemname)
			else
			   desc = desc..get_use_string(def)

			   player:hud_change(data.hud, 'text', desc)
			end
		end
	end
end)

