-------------------------------------
--Character Tab
--[[
Various Role playing information,
Player stats etc


]]

lore = lore

------------------------------------
--set character name and record start time

local function update_playtime(player, meta)
   if not meta then
      meta = player:get_meta()
   end
   local last = tonumber(meta:get_int("char_time_stamp"))
   local difference = minetest.get_gametime() - last
   local time = tonumber(meta:get_int("char_time_survived"))
   meta:set_int("char_time_survived", time + difference)
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
  local effects_list_str = meta:get_string("effects_list")
  local effects_list = minetest.deserialize(effects_list_str) or {}
  local bio = meta:get_string("bio")
  --backwards compatibility
  if bio == "" then
    --generate biography
    bio = lore.generate_bio(player)
  end

  local y = 3.1
  local eff_form = ""


  for _, effect in ipairs(effects_list) do
    --convert into readable
    -- (this would be better handled more flexibly, these might not suit all)
    local severity = effect[2] or 0
    if severity == 0 then
      severity = ""
    elseif severity == 1 then
      severity = "(mild)"
    elseif severity == 2 then
      severity = "(moderate)"
    elseif severity == 3 then
      severity = "(severe)"
    elseif severity >= 4 then
      severity = "(extreme)"
    end

    y = y + 0.4
    eff_form = eff_form.."label[0.1,"..y.."; "..effect[1].." "..severity.."]"
  end

	local formspec = "label[0.1,0.1; Name: " .. name .. "]"..
	"label[4,0.1; Days Survived: " .. days .. "]"..
	"label[4,0.6; Lives: " .. lives .. "]"..
  "label[0.1,1.1; Biography: " .. bio .. "]"..
  "label[0.1,3.1; Health Effects:]"..
  eff_form


	return formspec
end



local function register_tab()
	sfinv.register_page("lore:char_tab", {
		title = "Character",
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
