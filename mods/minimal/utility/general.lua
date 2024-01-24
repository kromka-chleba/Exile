minimal = minimal
S = minimal.S

function minimal.invlists2string(lists)
   local cleantable = {}
   if not lists then return end
   for listname, list in pairs(lists) do
      cleantable[listname] = {}
      for i = 1, #list do
	 cleantable[listname][i] = list[i]:to_string()
      end
   end
   return minetest.serialize(cleantable)
end
function minimal.string2invlists(string)
   local table = minetest.deserialize(string)
   if not table then return end
   local newlist = {}
   for listname, list in pairs(table) do
      newlist[listname] = {}
      for i = 1, #list do
	 newlist[listname][i] = ItemStack(list[i])
      end
   end
   return newlist
end

local __click_count_ready = {}
function minimal.click_count_ready(name, id, pos, count, timeout)
	-- { playername_id = { timeout=time() + __timeout, count = __use_count } }
	local timeout = timeout or 2 -- 2 second window for timeout
	local count = count or 3 -- number of clicks
	local ready = __click_count_ready[name.."_"..id]
	if ready and ready.pos == pos then
		ready.count = ready.count + 1
		if os.time() < ready.timeout then
			if ready.count >= count then
				__click_count_ready[name.."_"..id]  = nil
				return true
			else
				return false
			end
		end
	end
	__click_count_ready[name.."_"..id] = {
		timeout = os.time() + timeout,
		count = 1,
		pos = pos,
	}
	return false
end

function minimal.get_pointed_thing(player,rn, obj, liq)
   -- player, rn = custom "range" to override, return obj or liq if true
   -- get the player by name if string
  if (type(player) == "string") then
    player = minetest.get_player_by_name(player)
  end
  local range = 5 -- out to 5 nodes
  if not minetest.is_player(player) then
     error("exile_game.get_pointed_thing: Invalid player specified (or "..
	   "improper name), got type "..type(player))
  elseif type(rn) == "number" then
    -- override with provided range number if a number
    range = rn
  else
    -- get range of player's wielded item and use that
    local w_itemdef = player:get_wielded_item()
    w_itemdef = w_itemdef:get_definition()
    if w_itemdef and type(w_itemdef.range) == "number" then
      range = w_itemdef.range
    end
  end
   local ppos = player:get_pos()
   local eye_height = player:get_properties().eye_height
   ppos.y = ppos.y + eye_height
   local lookdir = vector.multiply(player:get_look_dir(), range)
   local pointpos = vector.add(ppos, lookdir)
   local ray = minetest.raycast(ppos, pointpos, obj or false, liq or false)
   local point
   repeat
      point = ray:next()
   until ( not point ) -- nil
      or point.type == "node"
      or (point.type == "object" and point.ref ~= player) -- object + not player
   return point
end

function minimal.swap_tool(player, wielded_item, newtool)
   local wear = wielded_item:get_wear()
   local meta = wielded_item:get_meta():to_table()
   local newstack = ItemStack(newtool)
   newstack:set_wear(wear)
   newstack:get_meta():from_table(meta)
   player:set_wielded_item(newstack)
end


function minimal.sanitize_string(badstring)
  assert(type(badstring) == "string","exile_game.sanitize_string: Invalid badstring given, got "..type(badstring))
   local disallowed = { "\\", "{", "}", "^", ";",
			--lua magic characters
			"%(", "%)", "%[", "%]", "%.", "%$",
			"%^", "%%", "%+", "%-", "%*", "%?"  }
   badstring:trim():lower()
   for i in ipairs(disallowed) do
      badstring = badstring:gsub(disallowed[i],"")
   end
   return badstring
end

-- merges content of t1 and t2 into a new table
-- if t1 and t2 contain identical keys, values from
-- t1 are overwritten with values from t2
function minimal.merge_tables(t1, t2)
  assert(type(t1) == "table", "exile_game.merge_tables: Invalid first table given, got "..type(t1))
  assert(type(t2) == "table", "exile_game.merge_tables: Invalid second table given, got "..type(t2))
    local new_table = table.copy(t1)
    --merge tables
    for key, value in pairs(t2) do
        new_table[key] = value
    end
    return new_table
end

function minimal.concat_tables(table_list)
  assert(type(table_list) == "table","exile_game.concat_tables: Invalid table_list given, got "..type(table_list))
  local new_table = {}
  local index = 1
  for tabl_nr = 1, #table_list do
      local current_table = table_list[tabl_nr]
      for z = 1, #current_table do
          new_table[index] = current_table[z]
          index = index + 1
      end
  end
  return table.copy(new_table)
end

function minimal.math_clamp(num,min,max)
  -- math.clamp implementation from my function library (TPH/TubberPupperHusker)
  -- PARAMETERS: num;"number" - number to be clamped
  -- min;"number" - minimum number that 'num' can be
  -- max;"number" - maximum number that 'num' can be
  -- RETURNS: number - 'num' that is clamped (between 'min' and 'max')
  -- FUNCTION: clamps a specified number between a min & max
  ------------------------------------------------------------------------------------------------------------------
  assert(type(num) == "number","math.clamp: no number provided to be clamped! got "..type(num))
  assert(type(min) == "number","math.clamp: no minimum number provided for clamping, got "..type(num))
  assert(type(max) == "number","math.clamp: no maximum number provided for clamping, got "..type(num))

  -- if num, min, and max are numbers then
  if (min > max) then -- if programmer puts max number in place of minimum number... don't punish them for it
    local temp = min -- create a temporary value so that 'min' can be stored
    min = max
    max = temp -- set 'max' to the temporary value
  end

  if (num < min) then
    num = min
  elseif (num > max) then
    num = max
  end
  -- "if elseif" statement because if it's lower than minimum then it's
  -- obviously not going to be greater than maximum and vice versa
  -- (and DO NOT clamp if the number is between min and max)

  return num
end


-- inspired by mobkit's "make_sound"
-- intended to play both mob sounds and custom sound files
function minimal.make_sound(params_table,sound_name)
  if type(params_table) == "string" and type(sound_name) == "table" then
    -- do a switcheroo for this function
    -- allows one to use this function like minetest.sound_play()
    local temp = sound_name
    sound_name = params_table
    params_table = temp
  end
  local sound_spec
  if type(params_table) == "string" then
    sound_spec = {name = params_table, gain = 0.5}
    return minetest.sound_play(sound_spec.name,sound_spec)
  elseif type(params_table) ~= "table" then
    -- not viable
    return
  end
  local function get_range(value)
    -- if value is a table and its index 1 and 2 are numbers then return a randomized value between them
    return type(value) == 'table' and type(value[1]) == "number" and type(value[2]) == "number" and
    (value[1]+math.random()*(value[2]-value[1]) ) or value
  end
  if type(sound_name) == "string" then
    -- assume it's a mob's sounds
    local look_through = params_table.sound or params_table.sounds
    if type(look_through) == "table" then
      sound_spec = params_table[sound_name]
    elseif not params_table.name then
      -- do not assume it's a mob's sounds
      sound_spec = minimal.merge_tables({name = sound_name}, params_table)
    end
  else
    sound_spec = params_table
  end
  if type(sound_spec) ~= "table" then
    return
  end
  if #sound_spec > 0 then
    sound_spec = sound_spec[math.random(#sound_spec)]
    if type(sound_spec) ~= "table" then
      -- if indexes are malformed - e.g. t[1] = value, t[2] = value, t[5] = value - math.random will index from 1-5, but 3 and 4 will be nil - then return nil
      return
    end
  end
  if not sound_spec.name then
    return
  end
  if not sound_spec.pos and not sound_spec.object then
    sound_spec.object = params_table.object
  end
  -- ensure no accidental overwrite
  sound_spec = table.copy(sound_spec)
  sound_spec.gain = get_range(sound_spec.gain)
  sound_spec.fade = get_range(sound_spec.fade)
  sound_spec.pitch = get_range(sound_spec.pitch)
  sound_spec.max_hear_distance = get_range(sound_spec.max_hear_distance)
  sound_spec.start_time = get_range(sound_spec.start_time)

  return minetest.sound_play(sound_spec.name,sound_spec)
end
function minimal.sound_play(...)
  return minimal.make_sound(...)
end



-- Yes or no dialog
--
-- "question" will be displayed to the player
-- "function_call" will be executed when the player clicks
-- "attached_data_table" will be passed through to function_call
--
-- format for the function:
-- local function name(clicked_yes, data_table, player, playername)
--
-- be careful with what you feed into data_table, if it contains an
-- inv that players can alter, it might cause  item duplication glitches

local open_yesno = {}
function minimal.yes_or_no(playername, question,
			   function_call, attached_data_table)
   if not playername then
      return
   end
   minetest.after( 0.1, function()
     minetest.show_formspec(
      playername, "minimal:yesno_form",
      "formspec_version[3]"..
      "size[7,4.5]"..
      "hypertext[0.5,0.75;6,2;introtext;"..
      question.."]"..
      "button_exit[1,3;2,1;Yes;"..S("Yes").."]"..
      "button_exit[4,3;2,1;No;"..S("No").."]"
     )
   end)
   open_yesno[playername] = { fcall = function_call,
			      data = attached_data_table }
end

minetest.register_on_player_receive_fields(function(player,
						    formname,fields)
      if formname ~= "minimal:yesno_form" then
	 return
      end
      local playername = player:get_player_name()
      local stored = open_yesno[playername]
      if not stored then
	 minetest.log("error", "Couldn't find an open yesno dialog"..
		      " for "..playername)
	 return
      end
      if fields.Yes then
	 stored.fcall(true, stored.data, player, playername)
      end
      if fields.No then
	 stored.fcall(false, stored.data, player, playername)
      end
      open_yesno[playername] = nil
end)

function minimal.item_pickup(clicker, pointed_thing)
  if (minetest.is_player(clicker) and type(pointed_thing) == "table") then
    if pointed_thing.type == "object" then
      local pt_ref = pointed_thing.ref
      local ent
      if pt_ref then
        ent = pt_ref:get_luaentity()
      end
      if ent then
        if ent.itemstring and ent.itemstring ~= "" then
          -- itemstring seems to save item metadata and wear :o
          local itemstack = ItemStack(ent.itemstring)
          local inv = clicker:get_inventory()

          if inv:room_for_item("main",itemstack) then
            inv:add_item("main",itemstack)
	    pointed_thing.ref:remove()
          else
	    minimal.warn_inv_full(clicker)
          end

          return true
        end
      end
    end
  end

  return false
end

-- itemstack storage functions
local function itemstack_equals(itemstack1,itemstack2)
  -- check if an itemstack equals the other by checking name and then meta if applicable
  if itemstack1:get_name() == itemstack2:get_name() then
    if itemstack1:get_meta() == itemstack2:get_meta() then
      return true
    end
  end
  return false
end
local function create_inventory_object(items, lengthoverride)
  if type(items) == "string" then
    if items == "" then
      items = {}
    else
      items = minetest.deserialize(items)
    end
  end
  if type(items) ~= "table" then
    return
  end
  -- create separate copy to use internally
  items = table.copy(items)
  -- check for and create proper inventory system
  for index,item in pairs(items) do
    -- convert or purify
    if type(item) ~= "userdata" or not item["is_empty"] then
      if type(item) == "string" then
        items[index] = ItemStack(item)
      else
        items[index] = ItemStack('')
      end
    end
  end
  -- add more slots if list is too small
  if #items < lengthoverride then
    for i = 1, lengthoverride do
      items[i] = ItemStack('')
    end
  end
  -- create custom functions for inventory object
  local inv = {}
  -- basic functions
  function inv:get_list()
    return items
  end
  function inv:to_string()
    for index,item in pairs(items) do
      if item:get_name() ~= "" then
        -- convert itemstack to string for serialization
        items[index] = item:to_string()
      else
        -- remove em
        items[index] = ""
      end
    end
    return minetest.serialize(items)
  end
  -- alias
  function inv:convert()
    return inv:to_string()
  end
  -- itemstack interactions
  function inv:room_for_item(itemstack)
    -- return false if cannot fit, return true if can fit, return false + number if full itemstack cannot fit but some of it can
    for _,item in pairs(items) do
      if item:get_name() == "" then
        return true
      end
    end
    for _,item in pairs(items) do
      if itemstack_equals(item,itemstack) then
        if item:item_fits(itemstack) then
          return true
        else
          -- return leftover
          return false,itemstack:get_count() - item:get_free_space()
        end
      end
    end
    -- can't fit it
    return false
  end
  function inv:add_item(itemstack, index)
    -- add itemstack and return leftover
    if type(index) ~= "number" then
      -- add normally
      for item_index,item in pairs(items) do
        -- if item equals provided itemstacked and there's space inside
        if item:get_free_space() > 0 and itemstack_equals(item,itemstack) then
          -- get the smallest number between the itemstack's count or the amount of space left
          local amt = math.min(itemstack:get_count(),item:get_free_space())
          itemstack:take_item(amt)
          item:set_count(item:get_count() + amt)
        end
        if itemstack:is_empty() then
          -- no point to iterating through if we're empty!
          break
        end
      end
      if not itemstack:is_empty() then
        for item_index,item in pairs(items) do
          if item:get_name() == "" then
            items[item_index] = itemstack
            return ItemStack('')
          end
        end
      end
    elseif minimal.math_clamp(index,1,#items) == index then
      -- index provided and is able to be indexed, add itemstack to index
      local item = items[index]
      if item:get_name() == "" then
        -- it's empty, fill it up
        items[index] = itemstack
        return ItemStack('')
      elseif itemstack_equals(item,itemstack) then
        if item:item_fits(itemstack) then
          itemstack = item:add_item(itemstack)
        else
          local amt = math.min(itemstack:get_count(),item:get_free_space())
          itemstack:take_item(amt)
          item:set_count(item:get_count() + amt)
        end
      end
    end
    return itemstack
  end
  function inv:remove_item(index,amount)
    -- take amount of item from an index
    if type(index) ~= "number" then
      return ItemStack('')
    end
    -- only if index is in range
    if minimal.math_clamp(index,1,#items) == index then
      amount = type(amount) == "number" and amount or 1 -- amount to take
      local item = items[index]
      -- what to return
      local itemstack = item:take_item(math.min(item:get_count(),amount))
      if item:is_empty() then
        items[index] = ItemStack('')
      end
      return itemstack
    end
  end
  function inv:get_full()
    -- get indexes of slots that are full
    local slots = {}
    for index,item in pairs(items) do
      if item:get_count() >= item:get_stack_max() then
        slots[#slots + 1] = index
      end
    end
    -- return table of slots + number
    return slots,#slots
  end
  function inv:get_partial()
    -- get indexes of slots that are partially full
    local slots = {}
    for index,item in pairs(items) do
      if item:get_count() > 0 then
        slots[#slots + 1] = index
      end
    end
    return slots,#slots
  end
  function inv:get_empty()
    -- get slots that are empty
    local slots = {}
    for index,item in pairs(items) do
      if item:is_empty() or item:get_name() == "" then
        slots[#slots + 1] = index
      end
    end
    return slots,#slots
  end
  return inv
end
function minimal.get_item_inventory(itemstack, metadata, inv_name)
  if type(itemstack) ~= "userdata" then
    return
  end
  metadata = type(metadata) == "userdata" and metadata or itemstack:get_meta()
  inv_name = type(inv_name) == "string" and inv_name or "inv_main"
  local inv = metadata:get(inv_name)
  if not inv then 
    return
  end
  local tool_def = itemstack:get_definition()
  local size = (tool_def.formspec_width or 8) * (tool_def.formspec_height or 4)
  return create_inventory_object(inv,size)
end
function minimal.set_item_inventory(itemstack, metadata, inv_name, inv)
  if type(itemstack) ~= "userdata" then
    return
  end
  if type(inv) ~= "string" then
    if type(inv) ~= "table" then
      return
    end
    if type(inv["convert"]) == "function" then
      -- utilize to_string function
      inv = inv:convert()
    else
      -- convert into an inventory object if no string indexes, otherwise return
      for index,value in pairs(inv) do
        if type(index) ~= "number" then
          return
        end
      end
      inv = create_inventory_object(inv)
      inv = inv:convert()
    end
  end
  metadata = type(metadata) == "userdata" and metadata or itemstack:get_meta()
  inv_name = type(inv_name) == "string" and inv_name or "inv_main"
  metadata:set_string(inv_name,inv)
end
