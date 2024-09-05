-------------------------------------
--Character Tab
--[[
   Various Role playing information,
   Player stats etc


]]

lore = lore
sfinv = sfinv

local S = lore.S

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
      meta:set_string("char_name", lore.generate_name(3))
      meta:set_int("char_time_stamp", minetest.get_gametime())
      meta:set_int("char_time_survived", 0)
      meta:set_string("bio", lore.generate_bio(player))
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

--get data and create form
local function sfinv_get(self, player, context)
   local meta = player:get_meta()
   local name = meta:get_string("char_name")
   update_playtime(player, meta)
   local tsurv = tonumber(meta:get_string("char_time_survived"))
   local days = math.floor( tsurv / 1200 )
   local lives = meta:get_int("lives")
   local bio = meta:get_string("bio")
   --backwards compatibility
   if bio == "" then
      --generate biography
      bio = lore.generate_bio(player)
   end

   local y = 3.4
   local eff_form = ""
   local st = player_api.get_state(player)
   local labels = st:read_labels()
   for _, effect in ipairs(labels) do
      y = y + 0.4
      eff_form = eff_form.."label[0.1,"..y.."; "..effect[1]..
         (effect[1] ~= "" and " " or "") -- only add a space if effect[1] exists
         ..(effect[2] or "").."]"
   end

   local basetex = minetest.formspec_escape(
      player_api.get_current_texture(player) )

   local formspec = "label[0.1,0.1; "..S("Name").. ": ".. name .. "]"..
      "label[4,0.1; "..S("Days Survived")..": ".. days .. "]"..
      "label[4,0.6; "..S("Lives")..": " .. lives .. "]"..
      "label[0.1,1.1; "..S("Biography")..": " .. bio .. "]"..
      "style[player_settings;border=false]"..
      "image_button_exit[7,0.15;0.75,0.75;gear.png;player_settings;]"..
      "label[0.65,3.1; "..S("Health Effects")..":]"..
      eff_form..
      "image[0,3.05;0.65,0.65;hud_sick.png]"..
      "model[6.5,6;2,3;character;character.b3d;"..basetex..
      ";-20,160;;true;;]"


   return formspec
end



local function register_tab()
   sfinv.register_page(
      "lore:char_tab", {
         title = S("Character"),
         --on_enter = function(self, player, context)
         --sfinv.set_player_inventory_formspec(player)
         --end,
         get = function(self, player, context)
            local formspec = sfinv_get(self, player, context)
            return sfinv.make_formspec(player, context, formspec, false)
         end
   })
end

register_tab()
