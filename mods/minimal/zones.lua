--zones.lua
--
-- Defines a region of the map that can have special treatment by other mods
--

-- API functions appear after setup and utility sections

local S = core.get_translator(minimal.modname)

-- Zone setup ------------------------------------------------------------
local checkrate = 59 -- Seconds between checking for expired zones
local zoneduration = 100 -- seconds before a zone is eligible to expire

zone = {} -- namespace

zone.shapes = { -- Readable names for the shape that the zone effect takes
   ["absolute"] = 1, -- Either 100% effect or none, with no gradient to edges
   ["radial"] = 2, -- A spherical effect, constrained by narrowest axis
   ["cylindrical"] = 3, -- Like radial, but ignoring y axis
   ["cubic"] = 4, -- Cubic shape with noticeable corners
} -- WARNING: If you add more, add them on the end or existing zones will change

local zs = zone.shapes

-- An individual zone, containing its specific settings and data
-- Can have multiple valid zonetypes, per zonetype-key in data table
local zonedef_default = {
   id = "",
   -- ID of the zone, created when the trigger is first placed
   -- all copies will have the same id
   pos1 = vector.new(), -- lower corner
   pos2 = vector.new(), -- upper corner
   base = vector.new(), -- base for relative positions
   zt_sel = nil, -- selection of trigger type, a string named like the type
   zt_tabsel = "1", -- currently active tab
   zt_label = "",
   shape = zs.absolute,
   logarithmic = "false",-- Do non-absolute zones fade logarithmically w/distance
   triggerpos = {}, -- list of known triggers that connect to this
   --ztrd_"nm" = {}
   -- set up by calling mod, in: handle_formspecs, out: zone.check()
}
--[[ Ephemeral values, added when zone is created, but not stored in meta
   lastcheck = 0, -- How long since we last checked if zone is loaded
   size = { x = 0, y = 0, z = 0 },
   lasttrigger = vector.new(), -- pos of last seen trigger, for expiration
   midpoint = vector.new(),
   narrowest = 0, -- Narrowest axis, for radial/cylindrical shapes
]]--


local zonelist = {} -- Stores all zones by id, primary store of data for each
--[[
   ["id"] = { zonedef }
]]--
local zonebytype = -- stores all ids that pertain to a zone type
   {
      -- ["ztr_reset"] = { id1 = true, id2 = true, id3 = true, ...}
   }

local zoneinfo = {}
-- stores data concerning all possible zone types, set up by zone.register()

local zone_formspec -- function defined far below, but used in save code
 -- Formspec needs to be able to call sink_zone() when the Set button is pressed
 -- Meanwhile, metaset() has to be able to synchronize all node's formspecs
 -- #TODO: better solution? Store current fs in table, only update with func?

------------------------------------------------------------
-- Utility functions

local function generate_id(pos)
   return minetest.sha1(tostring(minetest.get_gametime())..
			minetest.pos_to_string(pos))
end

local function add_zbts(id)
   -- Inserts a zone's id to all appropriate zone_by_type lists
   if not zonelist[id] then
      error("attempted to add zbt data for nonexistant id!")
   end
   for nm, _ in pairs(zoneinfo) do
      local check = zonelist[id]["ztrd_"..nm]
      if check and check ~= {} and check ~= "" then
	 zonebytype[nm][id] = true
      end
   end
end

local function clear_zbt(id, rmtype)
   if not zonelist[id] then
      error("attempted to remove zbt data for nonexistant id!")
   end
   zonebytype[rmtype][id] = nil
end

local function calc_size(def)
   -- Cache various useful data about our zone's edges
   def.pos1, def.pos2 = vector.sort(def.pos1, def.pos2)
   def.size = {}
   for _, dir in pairs({"x", "y", "z"}) do
      def.size[dir] = def.pos2[dir] - def.pos1[dir]
   end
   def.narrowest = def.size.x
   if def.size.y < def.narrowest then
      def.narrowest = def.size.y
   end
   if def.size.z < def.narrowest then
      def.narrowest = def.size.z
   end
   def.radius = { x = def.size.x / 2,
		  y = def.size.y / 2,
		  z = def.size.z / 2, }
   def.midpoint = vector.new()
   for _, dir in pairs({"x", "y", "z"}) do
      def.midpoint[dir] = def.pos1[dir] + def.radius[dir]
   end
end

function zone.get_corner(pos1, pos2, base, number)
   -- Find a specific corner, or get a table of all eight if number is nil
   -- Returns absolute positions
   local count = 0
   local list
   if number == nil then
      number = 0
      list = {}
   end
   local tbl = {vector.add(pos1, base), vector.add(pos2, base)}
   for cz in pairs(tbl) do
      for cy in pairs(tbl) do
	 for cx in pairs(tbl) do
	    count = count + 1
	    local curpos = { x = tbl[cx].x, y = tbl[cy].y, z = tbl[cz].z }
	    if count == number then
	       return curpos
	    elseif number == 0 then
	       list[count] = curpos
	    end
	 end
      end
   end
   return list
end

-- Check whether pos is inside the specified zone
-- Returns a depth number, 0 for not inside, 1 is max depth/effect
local function inside_depth(pos, zdef)
   if not zdef.base then return 0 end
   local p1 = vector.add(zdef.pos1, zdef.base)
   local p2 = vector.add(zdef.pos2, zdef.base)
   local midpoint = vector.add(zdef.midpoint, zdef.base)
   if not ( pos.x >= p1.x and pos.x <= p2.x and
	    pos.y >= p1.y and pos.y <= p2.y and
	    pos.z >= p1.z and pos.z <= p2.z ) then
      return 0 -- Outside the box entirely
   end
   -- Okay, we're inside, now how far?
   if ( not zdef.shape ) or ( zdef.shape == zs.absolute) then
      -- absolute is either in the zone or out
      return 1
   end
   local depth = 0-- how far in we are, range 0.01 - 1.00
   local distance = vector.distance(midpoint, pos)
   if zdef.shape == zs.radial then
      -- A circular radius, defined by the smallest axis of the zone
      depth = (1 / ( zdef.narrowest/2) ) * ( zdef.narrowest / 2 - distance )
   elseif zdef.shape == zs.cubic then
      -- A square shape, where edges and corners are all equal values
      local distancex = math.abs(pos.x - midpoint.x)
      local distancey = math.abs(pos.y - midpoint.y)
      local distancez = math.abs(pos.z - midpoint.z)
      local xdepth = (1 / zdef.radius.x ) * ( zdef.radius.x - distancex )
      if xdepth < 0 then xdepth = 0 end
      local ydepth = (1 / zdef.radius.y ) * ( zdef.radius.y - distancey )
      if ydepth < 0 then ydepth = 0 end
      local zdepth = (1 / zdef.radius.z ) * ( zdef.radius.z - distancez )
      if zdepth < 0 then zdepth = 0 end
      depth = xdepth -- pick the largest value of the three
      if ydepth > depth then depth = ydepth end
      if zdepth > depth then depth = zdepth end
   elseif zdef.shape == zs.cylindrical then
      local cdistance = vector.distance(vector.new(pos.x,0,pos.z),
					vector.new(midpoint.x,0,midpoint.z))
      depth = ( 1 / ( zdef.narrowest / 2 ) ) * ( zdef.narrowest / 2 - cdistance )
   end
   if zdef.logarithmic == "true" then
      -- translate linear 0.1-1.0 to log 0.1-1.0
      -- "1.00 - depth" -- flip it, so the log falloff is inverted
      -- "1 - " -- but flip it back so it goes the right direction
      depth = 1 - 10^((1.00 - depth) / 1 * 2 - 2)
      -- It looks stupid, but it works!
      -- 25% into the field is now 68% effect, not 3%; 50% in is 90% , not 10%
      --str = str.." .. Add logarithmic falloff : "..tostring(depth)
   end
   if depth < 0 then depth = 0 end
   return depth
end

------------------------------------------------------------
-- API Interface

function zone.register(tr_name, tr_help, formspecfunc, procfieldfunc)
   --[[
      Registers a type of zone.

      tr_name should start with the calling mod's name or a short prefix
       example: cli_tmp -- stored here as ztrd_cli_tmp
      tr_help is a table. The first string is the name of the zone type,
       the second is a longer descriptive string.

      formspec should return a formspec page with fields for your data;
       zonedef will be sent as a parameter; your data is stored in  "ztrd_"..name
      buttons "btn_set"/"btn_unset" will be added automatically if missing
      procfields will be sent the fields from the formspec and should transform
       them into a table of values to be stored in zonelist[]

      if the procfields function returns nil, your zone's data will be cleared
       #TODO: accept list of valid/invalid fields, highlight invalid ones?
       Requires fancy formspec work

      for safety, the table of values should contain strings or tables,
       no vectors or functions!  serialize them on your end.
   ]]--

   local name = tr_name
   zoneinfo[name] = { help = tr_help, formspec = formspecfunc,
		      procfield = procfieldfunc }
   zonebytype[name] = {}
end

function zone.check(pos, zone_type)
   -- Call this to ask if a pos is inside a zone of your "zone_type"
   -- Return value is depth and current zone fields
   if not zonebytype[zone_type] then
      minetest.log("error", "attempted to check non-existent zone type "..
		   dump(zone_type))
      return
   end
   local list = {}
   for id, _ in pairs(zonebytype[zone_type]) do
      local result = inside_depth(pos, zonelist[id])
      if result > 0 then
	 table.insert(list, {depth = result,
			     settings = zonelist[id]["ztrd_"..zone_type] })
      end
   end
   return list
end

------------------------------------------------------------
-- Loading and saving active zones

local function metaload(meta) -- Deserialize zonedef values from meta
   local function getval(met, str)
      if type(met) == "table" then return met[str]
      else return met:get(str) end
   end
   local def = table.copy(zonedef_default)
   local mid = getval(meta,"ztr_id")
   for key, _ in pairs(zonedef_default) do
      local val = getval(meta,"ztr_"..key)
      if val then
	 if vector.check(zonedef_default[key]) then -- It's a vector!
	    val = minetest.deserialize(val) or val
	    val = vector.new(val.x, val.y, val.z)
	 elseif type(zonedef_default[key]) == "table" then
	    val = minetest.deserialize(val) or val
	 end
	 if type(zonedef_default[key]) == "number" then
	    val = tonumber(val)
	 end
	 if key == "triggerpos" then
	    for i = 1, #val do -- Ensure the memory values are proper vectors
	       val[i] = vector.new(val[i].x, val[i].y, val[i].z)
	    end
	 end
	 def[key] = val
      end
   end
   for nm, _ in pairs(zoneinfo) do
      local val = getval(meta,"ztrd_"..nm)
      if val then
	 def["ztrd_"..nm] = minetest.deserialize(val)
      end
   end
   calc_size(def)
   return def, mid
end

local function hoist_zone(meta, pos) -- Set up new zonedef from meta
   local zdef, zoneid = metaload(meta) -- hoist from inventory
   if not zoneid then -- new zone, create an id
      if not pos then
	 -- shouldn't happen unless digging a busted trigger somehow
	 return nil, nil
      end
      zoneid = generate_id(pos)
      zdef.id = zoneid
   end
   if not zonelist[zoneid] then -- zone hasn't been seen yet, add it to the lists
      zonelist[zoneid] = zdef
      add_zbts(zoneid)
   end
   return zoneid
end

local function metaset(meta, def)
   -- Copy serialized definition values to a MetaDataRef
   if not def then
      error("No def received!")
      return
   end
   for key, _ in pairs(zonedef_default) do
      local val = def[key]
      if type(zonedef_default[key]) == "table" then
	 val = minetest.serialize(val)
      end
      if vector.check(zonedef_default[key]) and -- It's supposed to be a vector!
	 vector.check(val) then -- and it is
	 val = minetest.pos_to_string(val)
      end
      meta:set_string("ztr_"..key, val)
   end
   for nm, _ in pairs(zoneinfo) do

      local setting = def["ztrd_"..nm]
      if setting then
	 if setting == "" then -- erase removed keys
	    meta:set_string("ztrd_"..nm, "")
	    -- should we clean up "" from zlist mem so it doesn't redelete?
	    -- must be done elsewhere, this has to run once per node
	 else
	    meta:set_string("ztrd_"..nm, minetest.serialize(def["ztrd_"..nm]))
	 end
      end
   end
   if meta.set_tool_capabilities then -- this is an item, set description
      meta:set_string("description", "Zone trigger: "..
		      (def.zt_label or ""))
   end
   if meta.get_inventory then -- this is a node, set infotext
      meta:set_string("formspec", zone_formspec(zonelist[def.id]))
      meta:set_string("infotext", def.zt_label)
   end
end

local function sink_zone(def) -- Write zonedef values out to all known triggers
   if not zonelist[def.id] then return end
   local triggers = def.triggerpos
   if triggers then
      for c = 1, #triggers do
	 local meta = minetest.get_meta(triggers[c])
	 metaset(meta, def)
      end
   end
   -- Also update copies of this trigger in player inventory
   for _, player in ipairs(minetest.get_connected_players()) do
      local plinv = player:get_inventory()
      local main = plinv:get_list("main")
      for i = 1, #main do
	 local stack = main[i]
	 if minetest.get_item_group(stack:get_name(), "trigger") == 2 then
	    local imeta = stack:get_meta()
	    if imeta:get_string("ztr_id") == def.id then
	       metaset(imeta, def)
	    end
	 end
      end
      plinv:set_list("main", main)
   end
end

local ins = {} -- Instance list: temporarily hold zones while a schematic loads

function zone.instance(newpos, ztable)
   -- Internally used by Exile when loading a zone from schematic

   -- newpos is the trigger position to save metadata to
   -- ztable has the metadata.fields loaded from schematic, in a table format

   -- must call zone.instance() after to clear the table for the next schematic
   --  and load zones into memory


   local function copy_from_ins(ztb, oid)
      -- A trigger with this zone id was seen earlier, copy it from memory.
      for k, v in pairs(ins[ztb.ztr_id]) do
	 ztb[k] = v
      end
      ztb.ztr_thispos = newpos -- and shift thispos
      return ztb
   end
   if newpos == nil then   -- Hoist all zones in instance table now
      for _, dat in pairs(ins) do
	 local def, id = metaload(dat)
	 local label = dat.ztr_zt_label or "unnamed"
	 dat.ztr_zt_label = label.." (instance)"
	 zonelist[id] = def
	 add_zbts(id)
      end
      ins = {} -- and wipe the table clean we're done with this schematic
      return
   end

   local oid = ztable.ztr_id -- original id, before it's overwritten
   if oid and ins[oid] then
      ztable.ztr_thispos = minetest.serialize(newpos)
      return copy_from_ins(ztable, oid) -- restore from previously seen table
   end
   ztable.ztr_id = generate_id(newpos)
   local thispos = minetest.deserialize(ztable.ztr_thispos)
   local base = minetest.deserialize(ztable.ztr_base)
   local offset = vector.subtract(newpos, thispos)
   base = vector.add(base, offset)
   ztable.ztr_base = minetest.serialize(base)
   ztable.ztr_thispos = minetest.serialize(newpos)
   local trigtable = minetest.deserialize(ztable.ztr_triggerpos)
   for i = 1, #trigtable do
      local item = vector.add(trigtable[i], offset)
      trigtable[i] = item
   end
   ztable.ztr_triggerpos = minetest.serialize(trigtable)
   ins[oid] = table.copy(ztable) -- store this for the next trigger of this zone
   ins[oid].ztr_thispos = nil -- but not "thispos" as it will change
   return ztable
end



------------------------------------------------------------
-- Expiring of inactive zones

local function clear_zbts_for_id(id)
   -- Removes all zbts for an id, for use prior to expiring it
   if not zonelist[id] then
      error("attempted to remove zbt data for nonexistant id!")
   end
   for nm, _ in pairs(zonebytype) do
      clear_zbt(id, nm)
   end
   sink_zone(zonelist[id])
end

local function remove_trigger(pos, id)
   local def = zonelist[id]
   if not def then return end -- zone is cleared already
   local trigpos = def.triggerpos
   local count = 1
   for i = 1, #trigpos do
      if trigpos[count]:equals(pos) then
	 table.remove(trigpos, i)
      else
	 count = count + 1 -- table.remove shortens the table, use instead of i
      end
   end
   if vector.equals(def.base, pos) then -- we're removing the base node!
      if #trigpos > 0 then -- we have another trigger, use it for new base
	 local diff = vector.subtract(trigpos[1], def.base)
	 def.base = trigpos[1]
	 -- and move our pos1/pos2 to be relative to the new base
	 def.pos1 = vector.add(def.pos1, diff)
	 def.pos2 = vector.add(def.pos2, diff)
      else
	 clear_zbts_for_id(id)
	 zonelist[id] = nil -- No more triggers, clear the zone
      end
   end
   sink_zone(id)
end

local function node_is_loaded(pos, id)
   if not vector.check(pos) then return false end -- it's a bad entry
   local node = minetest.get_node(pos)
   if node.name == "ignore" then
      return false
   else
      return true
   end
end

local function check_corners_loaded(def)
   -- Looks at all eight corners of a zone to see if any are loaded
   -- Returns a loaded corner if it exists, so we can track it

   local tbl = {vector.add(def.pos1, def.base), vector.add(def.pos2, def.base)}
   for cz in pairs(tbl) do
      for cy in pairs(tbl) do
	 for cx in pairs(tbl) do
	    local checkme = vector.new{ x = tbl[cx].x, y = tbl[cy].y,
					z = tbl[cz].z }
	    if node_is_loaded(checkme) then
	       return checkme
	    end
	 end
      end
   end
   return false
end

local function check_triggers_loaded(id, def)
   if not def then return end -- no zonelist entry to check!
   if not def.triggerpos then -- Zone has no triggers? Remove it
      zonelist[id] = nil
      return
   end
   local count = 1
   for i = 1, #def.triggerpos do
      if def.triggerpos[count] then
	 local node = minetest.get_node(def.triggerpos[count])
	 if node.name ~= "minimal:zone_trigger" then
	    remove_trigger(def.triggerpos[count], id)
	 else
	    count = count + 1
	 end
      end
   end
end

local function check_for_expiry()
   local expireme = {}
   for id, testing in pairs(zonelist) do
      local ctime = minetest.get_gametime()
      if not testing.lastcheck or
	 ( ctime > (testing.lastcheck + zoneduration)
	   and not node_is_loaded(testing.lastcorner) ) then
	    local result = check_corners_loaded(testing)
	    if result == false then -- no corners loaded anymore
	       table.insert(expireme, testing.id)
	    else -- update lastcorner with this still-loaded node
	       testing.lastcorner = result
	       testing.lastcheck = ctime
	    end
      end
      check_triggers_loaded(id, testing)
   end
   for i = 1, #expireme do
      minetest.log("action", "Expired id: ",expireme[i])
      expireme[i] = nil  -- do nothing yet, just empty the table
   end
end

local timer = 0
minetest.register_globalstep(function(dtime)
      timer = timer + dtime
      if timer > checkrate then
	 timer = 0
	 check_for_expiry()
      end
end)


-- Formspec --------------------------------------------------------------

local dropdownstring = ""
local index = {} -- find the index number of a zone type from its name
local rindex = {} -- find the name of a zone type from its index
local idx = 1
local comma = "" -- no comma before the first, or after the last

minetest.register_on_mods_loaded(function()
      for nm, val in pairs(zoneinfo) do
	 dropdownstring = dropdownstring..comma..val["help"][1]
	 index[nm] = idx
	 rindex[idx] = nm
	 idx = idx + 1
	 comma = ","
      end
end)

local function zone_range(def)
   if not def.base or not def.pos1 or not def.pos2 then
      return "label[0.5,0.5;Error in zone def ranges]"
   end
   local p1 = vector.add(def.pos1, def.base) -- to absolute coords
   local p2 = vector.add(def.pos2, def.base)
   local formspec =
      "label[0.375,0.5;Upper corner]label[4.35,0.5;( North / Up / East )]"..
      "button[0.5,1.0;0.25,0.5;upperx-;-]"..
      "field[0.75,1.0;1.5,0.5;upperx;X;"..p2.x.."]"..
      "button[2.25,1.0;0.25,0.5;upperx+;+]"..
      "button[2.5,1.0;0.25,0.5;uppery-;-]"..
      "field[2.75,1.0;1.5,0.5;uppery;Y;"..p2.y.."]"..
      "button[4.25,1.0;0.25,0.5;uppery+;+]"..
      "button[4.5,1.0;0.25,0.5;upperz-;-]"..
      "field[4.75,1.0;1.5,0.5;upperz;Z;"..p2.z.."]"..
      "button[6.25,1.0;0.25,0.5;upperz+;+]"..
      "button[6.75,1.0;1,0.5;upperhere;Here]"..
      "button[7.25,2;1,0.5;setrange;Set]"..
      "label[0.375,2.5;Lower corner]label[4,2.5;( South / Down / West )]"..
      "button[0.5,3.0;0.25,0.5;lowerx-;-]"..
      "field[0.75,3.0;1.5,0.5;lowerx;X;"..p1.x.."]"..
      "button[2.25,3.0;0.25,0.5;lowerx+;+]"..
      "button[2.5,3.0;0.25,0.5;lowery-;-]"..
      "field[2.75,3.0;1.5,0.5;lowery;Y;"..p1.y.."]"..
      "button[4.24,3.0;0.25,0.5;lowery+;+]"..
      "button[4.5,3.0;0.25,0.5;lowerz-;-]"..
      "field[4.75,3.0;1.5,0.5;lowerz;Z;"..p1.z.."]"..
      "button[6.25,3.0;0.25,0.5;lowerz+;+]"..
      "button[6.75,3.0;1,0.5;lowerhere;Here]"..
      "label[1,4;Range type:]"..
      "label[1.5,4.5;( Absolute is either inside or out. )]"..
      "label[1.5,5;( Radial and cubic fade towards the edge. )]"..
      "dropdown[1,5.5;3,1;rangetype;Absolute,Radial,Cylindrical,Cubic;"..
      tostring(def.shape)..";true]"..
      "field[3,8;6,0.5;zt_label;Label;"..def.zt_label.."]"

   if def.shape > 1 then
      formspec = formspec .. "label[4.25,6;with]"..
	 "checkbox[5,6;falloff;Logarithmic falloff;"..
	 (def.logarithmic).."]"
   end
   return formspec
end

function zone_formspec(def) -- actually local, see top of file
   local tabsel = def["zt_tabsel"] or "1" -- tab #
   local sel = def["zt_sel"] or rindex[1] -- name of selected zone type
   local formspec = "formspec_version[6]size[10.5,11]"..
      "tabheader[0,0;zt_tabsel;Range,Copy,Values;"..tabsel.."]"
   if tabsel == "1" then
      formspec = formspec..zone_range(def)
   elseif tabsel == "3" then
      local data = zoneinfo[sel]
      formspec = formspec..
	 "dropdown[0.6,0.6;3,0.8;zt_trigger;"..
	 dropdownstring..";"..index[sel]..";true]"..
	 "label[3.3,2;"..data["help"][1].."]"..
	 zoneinfo[sel]["formspec"](def["ztrd_"..sel] or {})
      if ( not string.match(formspec, ";btn_set;") and
	   not string.match(formspec, ";btn_unset;") ) then
	 formspec = formspec ..
	    "button[7.85,3.375;1.25,0.75;btn_set;" .. S("Set") .. "]"..
	    "button[9.25,3.375;1.25,0.75;btn_unset;" .. S("Unset") .. "]"
      end
   end
   return formspec
end


local function ADJbuttons(def, fields) -- Handle the dozen different +/- buttons
   local corners = {"lower", "upper"}
   local dirs = { "-", "+" }
   local move = { upper = vector.new(), lower = vector.new() }
   for c = 1, #corners do
      for _, axis in pairs({"x","y","z"}) do
	 for d = 1, #dirs do
	    if fields[corners[c]..axis..dirs[d]] then
	       if ( c == 1 and d == 2 or -- Don't add to pos1 if it matches pos2
		    c == 2 and d == 1 ) and -- and don't subtract vice versa
		  def.pos1[axis] >= def.pos2[axis] then
		  return
	       end
	       move[corners[c]][axis] = tonumber(dirs[d].."1")
	    end
	 end
      end
   end
   def.pos1 = vector.add(def.pos1, move["lower"])
   def.pos2 = vector.add(def.pos2, move["upper"])
end


local function ztrecfields(pos, formname, fields, sender)
   local function abs_to_relative(field, offset) -- translation of pos1, pos2
      if fields.lowerx == nil then return nil, nil end -- not set
      local p1 = vector.new(fields.lowerx, fields.lowery, fields.lowerz)
      local p2 = vector.new(fields.upperx, fields.uppery, fields.upperz)
      p1 = vector.subtract(p1, offset)
      p2 = vector.subtract(p2, offset)
      return vector.sort(p1, p2)
   end
   local def
   local function dofield(fieldname, storedname)
      local value = fields[fieldname]
      if value then
	 if value ~= "" then
	    if type(zonedef_default[storedname]) == "number" then
	       value = tonumber(value)
	    end
	    def[storedname] = value
	 else -- if it's "", then clear the value
	    def[storedname] = zonedef_default[storedname]
	 end
      end
   end
   local node = minetest.get_node(pos)
   local trtype = minetest.get_item_group(node.name, "trigger")
   if trtype == nil or trtype ~= 2 then return end
   local nmeta = minetest.get_meta(pos)
   local id = nmeta:get("ztr_id")
   def = zonelist[id]
   if not def then
      minetest.log("error", "No def found for id ",id)
      return
   end
   local saveout = false
   local p1, p2 = abs_to_relative(fields, def.base)
   def.pos1 = p1 or def.pos1
   def.pos2 = p2 or def.pos2
   local sel
   if fields.zt_trigger then
      sel = rindex[tonumber(fields.zt_trigger)]
      def["zt_sel"] = sel
   else
      sel = def["zt_sel"] or rindex[1]
   end
   dofield("zt_tabsel", "zt_tabsel")
   dofield("zt_label", "zt_label")
   dofield("rangetype", "shape")
   dofield("falloff", "logarithmic")
   ADJbuttons(def, fields)
   if fields.upperhere then
      def.pos2 = vector.subtract(pos, def.base)
      saveout = true
   end
   if fields.lowerhere then
      def.pos1 = vector.subtract(pos, def.base)
      saveout = true
   end
   if fields.btn_set then
      local settings = zoneinfo[sel].procfield(fields)
      if settings then
	 zonelist[id]["ztrd_"..sel] = settings
	 add_zbts(id)
      else
	 clear_zbt(id, sel)
      end
      saveout = true
   end
   if fields.btn_unset then
      clear_zbt(id, sel)
      saveout = true
   end
   if saveout or fields.setrange then
      calc_size(zonelist[id])
      sink_zone(zonelist[id])
   end
   local fs = zone_formspec(zonelist[id])
   nmeta:set_string("formspec", fs)
   nmeta:set_string("infotext", def.zt_label)
end

-- Nodes -----------------------------------------------------------------

minetest.register_node("minimal:zone_trigger", {
        description = "Exile zone trigger node",
        tiles = {"climate_air.png"},
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
	pointable = false,
        walkable = false,
        buildable_to = false,
        floodable = false,
        groups = {temp_pass = 1, trigger = 2},
	use_texture_alpha = "blend",
})

if minetest.is_creative_enabled() then
   minetest.override_item('minimal:zone_trigger', {
		drawtype = "glasslike",
		pointable = true,
		diggable = true,
		groups = {crumbly = 1, cracky = 3,
			  temp_pass = 1, trigger = 2},
        tiles = {
                "tech_paint_gp_spsq.png",
        },
	after_place_node = function(pos, placer, itemstack, pointed_thing)
	   local meta = minetest.get_meta(pos)
	   local serpos = minetest.serialize(pos)
	   meta:set_string("ztr_thispos", serpos)

	   local imeta = itemstack:get_meta()
	   local zoneid = hoist_zone(imeta, pos) -- hoist from inventory
	   -- add this node to the zone's list of trigger positions
	   local trigpos = zonelist[zoneid].triggerpos
	   local tcount = #trigpos + 1
	   if tcount == 1 then -- this is our only trigger for this zone
	      zonelist[zoneid].base = pos
	   end
	   trigpos[tcount] = pos
	   -- move inventory, in case items are stored inside for mod triggers
	   local minv = meta:get_inventory()
	   minv:set_size("main", 8*2)
	   local iinv = minimal.string2invlists(imeta:get_string("inventory"))
	   if iinv ~= "" and iinv ~= nil then
	      minv:set_lists(iinv)
	   end
	   sink_zone(zonelist[zoneid]) -- save all new trigger info
	end,
	preserve_metadata = function(pos, oldnode, oldmeta, drops)
	   local stack_meta = drops[1]:get_meta()
	   oldmeta.ztr_thispos = nil
	   local def, _ = metaload(oldmeta)
	   metaset(stack_meta, def)
	   local oinv = minetest.get_meta(pos):get_inventory()
	   local list = oinv:get_lists() -- #TODO: test when we have inv ztrigs
	   stack_meta:set_string("inventory", minimal.invlists2string(list))
	   stack_meta:set_string("tr_selected", oldmeta["tr_selected"])
	end,
	on_dig = function(pos, node, digger)
	   local meta = minetest.get_meta(pos)
	   local id = meta:get_string("ztr_id")
	   if not id then return false end
	   remove_trigger(pos, id)
	   local inv = digger:get_inventory()
	   if not inv then return end
	   local main = inv:get_list("main")
	   for i = 1, #main do
	      local stack = main[i]
	      if minetest.get_item_group(stack:get_name(), "trigger") == 2 then
		 local imeta = stack:get_meta()
		 if imeta:get_string("ztr_id") == id then
		    minetest.remove_node(pos)
		    return
		 end
	      end
	   end
	   return minetest.node_dig(pos, node, digger)
	end,
	on_receive_fields = function(...)
	   ztrecfields(...)
	end,
	on_destruct = function(pos)
	   local meta = minetest.get_meta(pos)
	   local zoneid = meta:get("ztr_id")
	   remove_trigger(pos, zoneid) -- just in case on_dig didn't run
	end,
   })
end

minetest.register_lbm({
      label = "zonetriggers",
      name = "minimal:zonetriggers",
      nodenames = "minimal:zone_trigger",
      run_at_every_load = true,
      action = function(pos, node, dtime_s)
	 hoist_zone(minetest.get_meta(pos), pos)
      end,
})

__DEBUG__ = __DEBUG__

if __DEBUG__ then
   minetest.register_chatcommand("inspectzone",{
	privs = "server",
	description = "Print list of zone ids, "..
	   "or dump a zone specified by partial id",
	func = function(name,param)
	   if not param or param == "" then -- list zones
	      local empty = true
	      for id, _ in pairs(zonelist) do
		 print(id)
		 empty = false
	      end
	      if empty then print("No zones are running.") end
	      return
	   end
	   for id, data in pairs(zonelist) do
	      print(type(id)," vs ",type(param))
	      if string.match(id, param) then
		 print("ID found ",id," : ")
		 for k,v in pairs(data) do
		    if k ~= "formspec" then
		       print(k," : ",dump(v))
		    end
		 end
		 return
	      end
	   end
	   print("No ID containing "..param.." was found")
	end
   })
   minetest.register_chatcommand("inspectzbts",{
	privs = "server",
	description = "Print list of zone-by-type entries, "..
	   "or list zoneids attached to a specific one",
	func = function(name,param)
	   if not param or param == "" then -- list zones
	      local empty = true
	      for entry, _ in pairs(zonebytype) do
		 print(entry)
		 empty = false
	      end
	      if empty then print("No zones are running.") end
	      return
	   end
	   for entry, ids in pairs(zonebytype) do
	      print(type(entry)," vs ",type(param))
	      if string.match(entry, param) then
		 print("Entry ",entry," : ",dump2(ids))
		 return
	      end
	   end
	   print("No entry names containing "..param.." was found")
	end
   })
end
