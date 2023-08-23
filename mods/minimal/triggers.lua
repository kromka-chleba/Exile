
--namespace
triggers = {}
triggers.player = {} -- for timeouts on effects
local S = core.get_translator(minimal.modname)

-- Functions: ------------------------------------------------------------

local usedlist = {} -- temporarily remember who has activated each trigger

local function usedrecently(pos, pname)
   -- Allows a trigger to be used by a player just once per server start
   -- #TODO: is it worth saving this to prevent stop/start to reuse triggers?
   local posstr = vector.to_string(pos)
   if usedlist[posstr] == nil then
      usedlist[posstr] = {} -- this trigger hasn't been used by <player> yet
      usedlist[posstr][pname] = true
      return false
   end
   if usedlist[posstr][pname] == true then
      return true
   end
end


-- Triggers: -------------------------------------------------------------

local function reset_player(player, pname, pos, nmeta, metastring)
   local pmeta = player:get_meta()
   player:set_hp(20)
   pmeta:set_string("energy", "1000")
   pmeta:set_string("hunger", "1000")
   pmeta:set_string("thirst", "100")
   return true
end

local function hurt_player(player, pname, pos, nmeta, metastring)
   local damage = tonumber(metastring) or 2
   player:punch(player, 1.0, {full_punch_interval = 1.0,
			   damage_groups = {fleshy=damage} }, nil)
   return true
end
local function sethealth(player, pname, pos, nmeta, metastring)
   local val = tonumber(metastring) or 20
   player:set_hp(val)
   return true
end

local function setenergy(player, pname, pos, nmeta, metastring)
   local val = tonumber(metastring)
   if not val then return end
   local pmeta = player:get_meta()
   pmeta:set_string("energy", val * 10) -- energy is 1-1000, tenths of percent
   return true
end
local function sethunger(player, pname, pos, nmeta, metastring)
   local val = tonumber(metastring)
   if not val then return end
   local pmeta = player:get_meta()
   pmeta:set_string("hunger", val * 10) -- 1-1000, same as energy
   return true
end
local function setthirst(player, pname, pos, nmeta, metastring)
   local val = tonumber(metastring)
   if not val then return end
   local pmeta = player:get_meta()
   pmeta:set_string("thirst", val) -- thirst is 1-100
   return true
end

local function teleport(player, pname, pos, nmeta, metastring)
   local vec = vector.from_string(metastring)
   if not vec then
      minetest.chat_send_player(pname, "Invalid teleport vector, "..
				"must be '(x,y,z)'")
      return
   end
   player:set_pos(vec)
end
local function relaport(player, pname, pos, nmeta, metastring)
   local vec = vector.from_string(metastring)
   if not vec then
      minetest.chat_send_player(pname, "Invalid teleport vector, "..
				"must be '(x,y,z)'")
      return
   end
   player:set_pos(vector.add(pos, vec))
end

local function clearinv(player, pname, pos, nmeta, metastring)
   metastring = "main"
   --[[
   if metastring ~= "main" and metastring ~= "cloths"
      and metastring ~="both" then
   -- #TODO: clearing clothing doesn't update player appearance, fix it
      return
      end ]]--
   local inv = player:get_inventory()
   if metastring == "main" or metastring == "both"  then
      inv:set_list("main", {})
   end
   if metastring == "cloths" or metastring == "both"  then
      inv:set_list("cloths", {})
      player_api.compose_cloth(player)
   end
end
local function setinventory(player, pname, pos, nmeta, metastring)
   metastring = "main" -- until we can set clothing inv too
   local plinv = player:get_inventory()
   local triginv = nmeta:get_inventory():get_list(metastring)
   plinv:set_list(metastring, triginv)
end
local function giveitem(player, pname, pos, nmeta, metastring)
   if usedrecently(pos, pname) then
      return -- You'll have to try harder for freebies, Jack
   end
   local stack = ItemStack(metastring)
   local inv = player:get_inventory()
   if inv:room_for_item("main", stack) then
      inv:add_item("main", stack)
   else -- no room for items? happy birthday to the ground!
      minetest.item_drop(stack, player, pos)
   end
end

local function setweather(player, pname, pos, nmeta, metastring)
   if usedrecently(pos, pname) then
      return -- Don't keep doing it
   end
   climate.set_weather_override(pname, player, metastring)
end
local function resetweather(player, pname, pos, nmeta, metastring)
   climate.set_weather_override(pname, player, "")
end

local function hide_hud(player, pname, pos, nmeta, metastring)
   HEALTH.hide_hud_elements(player, nil, metastring, )
end
local function showall_hud(player, pname, pos, nmeta, metastring)
   HEALTH.show_hud_elements(player, nil, "all")
end


triggers.defs = {
   ["tr_reset"] = reset_player,
   ["tr_hurt"] = hurt_player,
   ["tr_energy"] = setenergy,
   ["tr_hp"] = sethealth,
   ["tr_hunger"] = sethunger,
   ["tr_thirst"] = setthirst,
   ["tr_teleport"] = teleport,
   ["tr_relaport"] = relaport,
   ["tr_clearinv"] = clearinv,
   ["tr_setinv"] = setinventory,
   ["tr_giveitem"] = giveitem,
   ["tr_setweather"] = setweather,
   ["tr_resetweather"] = resetweather,
   ["tr_hudhide"] = hide_hud,
   ["tr_hudshow"] = showall_hud,
}

local info = {
   ["tr_reset"] = { "Reset player",
		    "Will reset player stats to full"},
   ["tr_hurt"]  = { "Hurt player", "Hits player for <value> damage, 1-20"},
   ["tr_energy"]= { "Set energy", "Set player energy to <value> percent"},
   ["tr_hp"]    = { "Set HP", "Set player hp to <value>, 0-20"},
   ["tr_hunger"]= { "Set hunger", "Set player hunger to <value> percent"},
   ["tr_thirst"]= { "Set thirst", "Set player thirst to <value> percent"},
   ["tr_teleport"]={"Teleport", "Send player an exact xyz position, "..
		       " ( 125, 9003, -57 )" },
   ["tr_relaport"]={"Relaport", "Send player a relative xyz distance, "..
		       " ( 1, 10, -5 )" },
   ["tr_clearinv"]={"Clear inventory", "Empties main inventory"},
   ["tr_setinv"]  ={"Set inventory", "Overwrite player inv with contents"},
   ["tr_giveitem"]={"Give item", "Gives an item, in itemstring format"},
   ["tr_setweather"]={"Set weather", "Changes weather displayed to player"..
			 "\nUse /set_weather help to list available weather."},
   ["tr_resetweather"]={"Reset weather", "Restores normal weather for player"},
   ["tr_hudhide"]={"Hide hud elements",
		   "Hide health/energy/thirst/hunger/\n"..
		      "temp/enviro_temp/effects by names, or all"},
   ["tr_hudshow"]={"Show hud elements","Restore all hidden hud elements"},
}

-- table of triggers with no input field
local noinputfield = {
   ["tr_reset"] = true,
   ["tr_clearinv"] = true,
   ["tr_setinv"] = true,
   ["tr_resetweather"] = true,
   ["tr_hudshow"] = true
}
--Register a function to add as a trigger
-- ex: triggers.register("tr_mytrigger", mytriggerfunc, false
--                       {"My Trigger", "This does custom stuff"}}
function triggers.register(name, trfunction, inputfield, infotable)
   triggers.defs[name] = trfunction
   info[name] = infotable
   if inputfield == true then
      noinputfield[name] = true
   end
end
function triggers.activate(pos, player, nodemeta)
   if not player or not minetest.is_player(player) then
      minetest.log("error", "Attempted to run a trigger at "..pos.x..
		   "/"..pos.y.."/"..pos.z..
		   "with no valid player!")
      return
   end
   pos = vector.round(pos)
   local posstr = vector.to_string(pos)
   local time = minetest.get_gametime()
   local pname = player:get_player_name()
   -- check if the player has already triggered this recently
   if triggers.player[pname] and triggers.player[pname][posstr] then
      if time - triggers.player[pname][posstr] < 2 then
	 return
      else -- timer has expired
	 triggers.player[pname][posstr] = nil
      end
   end
   minetest.chat_send_player(pname, "You activated a trigger at "..posstr)
   if not nodemeta then
      nodemeta = minetest.get_meta(pos)
   end
   local updphys = false
   for nm, func in pairs(triggers.defs) do
      local val = nodemeta:get_string(nm)
      if val ~= "" then
	 updphys = func(player, pname, pos, nodemeta, val)
      end
   end
   triggers.player[pname] = { [posstr] = time }
   if updphys then
      HEALTH.update_player_physics(player)
   end
end

-- Formspec --------------------------------------------------------------

local dropdownstring = ""
local index = {}
local rindex = {}
local idx = 1
local comma = ""
for nm, val in pairs(info) do
   dropdownstring = dropdownstring..comma..val[1]
   index[nm] = idx
   rindex[idx] = nm
   idx = idx + 1
   comma = ","
end

local function triggerpage(sel, value)
   local spec =
      "dropdown[0.6,0.6;3,0.8;Trigger;"..
      dropdownstring..";"..index[sel]..";true]"..
      "label[3.3,2;"..info[sel][2].."]"
   if not noinputfield[sel] then
      spec = spec.."textarea[3.3,3;3,1.5;input_value;" ..
	 S("Value:") .. ";" .. value .. "]"
   else
      local bool
      if value == "" then
	 bool = "False"
      else
	 bool = "True"
      end
      spec = spec.."label[3.3,3;"..bool.."]"
   end
   spec = spec.."button[7.85,3.375;1.25,0.75;btn_set;" .. S("Set") .. "]" ..
      "button[9.25,3.375;1.25,0.75;btn_unset;" .. S("Unset") .. "]"
   if sel == "tr_setinv" then
      spec = spec.."list[context;main;0,4;8,4;]list[current_player;"..
	 "main;0,8;8,4;]"
   end
   return spec
end

local function setformspec(pos)
   local nodemeta = minetest.get_meta(pos)
   local sel = nodemeta:get_string("tr_selected")
   if sel == "" then sel = "tr_reset" end
   local value = nodemeta:get_string(sel)
   local spec =  "formspec_version[6]size[10.5,11]"..triggerpage(sel, value)
   nodemeta:set_string("formspec", spec)
end

function recfields(pos, formname, fields, sender)
   local node = minetest.get_node(pos)
   local trtype = minetest.get_item_group(node.name, "trigger")
   if trtype == nil or trtype == 0 then return end
   local nmeta = minetest.get_meta(pos)
   local sel
   if fields.Trigger then
      sel = rindex[tonumber(fields.Trigger)]
      nmeta:set_string("tr_selected",sel)
   end
   if fields.btn_set then
      local new_value = "true"
      if fields.input_value then
	 new_value = fields.input_value:trim()
      end
      nmeta:set_string(sel, new_value)
   end
   if fields.btn_unset then
      nmeta:set_string(sel, "")
   end
end

-- Nodes -----------------------------------------------------------------

minetest.register_node("minimal:trigger", {
        description = "Exile trigger node",
        tiles = {"climate_air.png"},
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
	move_resistance = 1,
	pointable = false,
        walkable = false,
        buildable_to = false,
        floodable = false,
        groups = {temp_pass = 1, trigger = 1},
	use_texture_alpha = "blend",
})

if minetest.is_creative_enabled() then
   minetest.override_item('minimal:trigger', {
		drawtype = "glasslike",
		pointable = true,
		diggable = true,
		groups = {crumbly = 1, cracky = 3,
			  temp_pass = 1, trigger = 1},
        tiles = {
                "tech_paint_gp_x.png",
        },
	on_construct = function(pos, width, height)
	   setformspec(pos)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
	      recfields(pos, formname, fields, sender)
	      setformspec(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
	   local meta = minetest.get_meta(pos)
	   local imeta = itemstack:get_meta()
	   for nm, _ in pairs(triggers.defs) do
	      local val = imeta:get_string(nm)
	      if val ~= "" then
		 meta:set_string(nm, val)
	      end
	   end
	   local minv = meta:get_inventory()
	   minv:set_size("main", 8*2)
	   local iinv = minimal.string2invlists(imeta:get_string("inventory"))
	   if iinv ~= "" and iinv ~= nil then
	      minv:set_lists(iinv)
	   end
	   local infotext = imeta:get_string("description")
	   if infotext ~= "" then
	      meta:set_string("infotext", infotext)
	   end
	   meta:set_string("tr_selected",imeta:get_string("tr_selected"))
	   setformspec(pos)
	end,
	preserve_metadata = function(pos, oldnode, oldmeta, drops)
	   local stack_meta = drops[1]:get_meta()
	   local desc = ""
	   local pmcomma = ""
	   for nm, _ in pairs(triggers.defs) do
	      local val = oldmeta[nm] or ""
	      if val ~= "" then
		 stack_meta:set_string(nm, val)
		 desc = desc..pmcomma..nm:gsub("tr_","")
		 pmcomma = ", "
	      end
	   end
	   local oinv = minetest.get_meta(pos):get_inventory()
	   local list = oinv:get_lists()
	   stack_meta:set_string("inventory", minimal.invlists2string(list))
	   if desc ~= "" then
	      stack_meta:set_string("description", "Configured trigger\n"..desc)
	   end
	   stack_meta:set_string("tr_selected", oldmeta["tr_selected"])
	end,
   })
end
