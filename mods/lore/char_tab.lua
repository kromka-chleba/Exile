-------------------------------------
--Character Tab
--[[
Various Role playing information,
Player stats etc


]]

lore = lore
local S = lore.S
local FS = lore.FS
local F = minetest.formspec_escape

------------------------------------
--set character name and record start time

local function update_playtime(player, meta)
   if not meta then
      meta = player:get_meta()
   end
   if not meta:get("playtime_suspended") then
      local last = tonumber(meta:get_int("char_time_stamp"))
      local difference = minetest.get_gametime() - last
      local time = tonumber(meta:get_int("char_time_survived"))
      meta:set_int("char_time_survived", time + difference)
   end
   meta:set_int("char_time_stamp", minetest.get_gametime())
end

minetest.register_on_newplayer(function(player)
  local meta = player:get_meta()
  meta:set_string("char_name", lore.generate_name(3))
  meta:set_int("char_time_stamp", minetest.get_gametime())
  meta:set_int("char_time_survived", 0)
  meta:set_string("bio", lore.generate_bio(player))
  meta:set_int("lives", 1)
end)

minetest.register_on_joinplayer(function(player)
  local meta = player:get_meta()
  local lives = ( meta:get_int("lives") or 1 )
  local old = tonumber(meta:get_string("char_start_date"))
  if old then -- Character used the old busted "days lived" setup, migrate
     if minetest.is_singleplayer() then
	-- It was really only valid for singleplayer
	local dayslived = minetest.get_day_count() - old
	meta:set_int("char_time_survived", dayslived * 1200) -- seconds
     else -- Just clear it and start over for multiplayer
	meta:set_int("char_time_survived", 0)
     end
     meta:set_string("char_start_date", "") -- Migration over
  end
  meta:set_int("char_time_stamp", minetest.get_gametime())
  if lives == 0 then lives = 1 end
  meta:set_int("lives", lives)
end)

minetest.register_on_respawnplayer(function(player)
  local meta = player:get_meta()
  meta:set_int("char_time_stamp", minetest.get_gametime())
  meta:set_int("char_time_survived", 0)
  if player:get_meta():get_string("lore:character_manually_edited") == "" then
    meta:set_string("char_name", lore.generate_name(3))
    meta:set_string("bio", lore.generate_bio(player))
  end
  local lives = meta:get_int("lives") or 1
  meta:set_int("lives", lives + 1)
end)

minetest.register_on_leaveplayer(function(player)
  local meta = player:get_meta()
  local last = tonumber(meta:get_int("char_time_stamp"))
  local difference = minetest.get_gametime() - last
  local time = tonumber(meta:get_int("char_time_survived"))
  meta:set_int("char_time_survived", time + difference)
  meta:set_int("char_time_stamp", minetest.get_gametime())
end)

local time = 0
minetest.register_globalstep(function(dtime)
      time = time + dtime
      if time > 60 then
	 -- update all players
	 for _, player in pairs(minetest.get_connected_players()) do
	    update_playtime(player)
	 end
	 time = 0
      end
end)

------------------------------------

--Forms for sfinv

local effectnm =
   { ["Food Poisoning"] = S("Food Poisoning"),
     ["Dust Fever"] = S("Dust Fever"),
     ["Intestinal Parasites"] = S("Intestinal Parasites"),
     ["Tiku High"] = S("Tiku High"),
     ["Neurotoxicity"] = S("Neurotoxicity"),
     ["Hepatotoxicity"] = S("Hepatotoxicity"),
     ["Photosensitivity"] = S("Photosensitivity"),
     ["Meta-Stim"] = S("Meta-Stim"),
     ["Fungal Infection"] = S("Fungal Infection"),
     ["Drunk"] = S("Drunk"),
     ["Hangover"] = S("Hangover") }


--get data and create form
local function sfinv_get(self, player, context)
  local meta = player:get_meta()
  local name = meta:get_string("char_name")
  update_playtime(player, meta)
  local tsurv = tonumber(meta:get_string("char_time_survived"))
  local days = math.floor( tsurv / 1200 )
  local lives = meta:get_int("lives")
  local effects_list_str = meta:get_string("effects_list")
  local effects_list = minetest.deserialize(effects_list_str) or {}
  local bio = meta:get_string("bio")
  --backwards compatibility
  if bio == "" then
    --generate biography
    bio = lore.generate_bio(player)
  end

  local y = 3.6
  local eff_form = ""


  for _, effect in ipairs(effects_list) do
    --convert into readable
    -- (this would be better handled more flexibly, these might not suit all)
    local severity = effect[2] or 0
    if severity == 0 then
      severity = ""
    elseif severity == 1 then
       severity = "("..S("mild")..")"
    elseif severity == 2 then
       severity = "("..S("moderate")..")"
    elseif severity == 3 then
       severity = "("..S("severe")..")"
    elseif severity >= 4 then
       severity = "("..S("extreme")..")"
    end

    y = y + 0.4
    eff_form = eff_form.."label[0.1,"..y.."; "..
       effectnm[effect[1]].." "..severity.."]"
  end

  local formspec = "button[0.1,0.1;2,0.5;edit;" .. FS("Edit") .. "]"..
     "label[0.1,0.6; "..FS("Name").. ": ".. F(name) .. "]"..
     "label[4,0.6; "..FS("Days Survived")..": ".. F(days) .. "]"..
     "label[4,1.1; "..FS("Lives")..": " .. F(lives) .. "]"..
     "label[0.1,1.6; "..FS("Biography")..": " .. F(bio) .. "]"..
     "style[player_settings;border=false]"..
     "image_button_exit[7,0.15;0.75,0.75;gear.png;player_settings;]"..
     "label[0.1,3.6; "..FS("Health Effects")..":]"..
	   F(eff_form)


	return formspec
end



local function register_tab()
	sfinv.register_page("lore:char_tab", {
		title = S("Character"),
		--on_enter = function(self, player, context)
			--sfinv.set_player_inventory_formspec(player)
		--end,
		get = function(self, player, context)
			local formspec = sfinv_get(self, player, context)
			return sfinv.make_formspec(player, context, formspec, false)
		end,
		on_player_receive_fields = function(self, player, formname, fields)
			if not fields.edit then return end
			local meta = player:get_meta()
			local name = meta:get_string("char_name")
			local gend_map = {
				female = 1,
				male = 2,
				other = 3
			}
			local gend = gend_map[meta:get_string("gender")]
			local bio = meta:get_string("bio")
			minetest.show_formspec(player:get_player_name(), "lore:edit_char",
				"formspec_version[6]" ..
				"size[6,8.5]" ..
				"field[1,1;4,1;name;" .. FS"Name" .. ";" .. F(name) .. "]" ..
				"dropdown[1,2;2;gender;" .. FS"Female" .. "," .. FS"Male" .. "," .. FS"Other" .. ";" .. F(gend) .. ";true]" ..
				"textarea[1,3.5;4,3;bio;" .. FS"Biography" .. ";" .. F(bio) .. "]" ..
				"button_exit[1,6.5;2,1;save;" .. FS"Save" .. "]" ..
				"button_exit[3,6.5;2,1;cancel;" .. FS"Cancel" .. "]")
		end
	})
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local save = fields.save or fields.key_enter
		if formname ~= "lore:edit_char" or not save then
			return false
		end
		local meta = player:get_meta()
		local gend_map = {["1"] = "female", ["2"] = "male", ["3"] = "other"}
		local gend = gend_map[fields.gender]
		meta:set_string("char_name", fields.name)
		meta:set_string("bio", fields.bio)
		meta:set_string("gender", gend)
		meta:set_string("lore:character_manually_edited", "true")
		sfinv.set_page(player, "lore:char_tab") -- refresh text in char tab
		player_api.set_texture(player)
		return true
	end)
end

register_tab()
