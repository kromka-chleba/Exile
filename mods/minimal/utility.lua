minimal = minimal
S = minimal.S

function minimal.safe_landing_spot(pos)
   if pos == nil then return false end
   local dest_top = minetest.get_node({ x = pos.x, y = pos.y+1, z = pos.z })
   local dest_bot = minetest.get_node({ x = pos.x, y = pos.y  , z = pos.z })
   local floor = vector.new( pos.x, pos.y-1, pos.z )
   local dest_flr = minetest.get_node(floor)
   local def_top = minetest.registered_nodes[dest_top.name]
   local def_bot = minetest.registered_nodes[dest_bot.name]
   local def_flr = minetest.registered_nodes[dest_flr.name]
   if dest_top.name ~= "ignore" and ( def_top and
				      def_top.walkable == true ) then
      return false -- loaded a solid node
   end
   if dest_bot.name ~= "ignore" and ( def_bot and
				      def_bot.walkable == true ) then
      return false
   end
   if dest_flr.name == "ignore" or ( def_flr and
				     def_flr.walkable == true ) then
      return true
   end
   -- floor is not walkable, search below it for a walkable floor
   local count = 0
   repeat
      floor = vector.add(floor, vector.new(0, -1, 0))
      dest_flr = minetest.get_node(floor)
      def_flr = minetest.registered_nodes[dest_flr.name]
      count = count + 1
   until ( def_flr and def_flr.walkable == true ) or
      count == 20
   if count == 20 then -- a 20 node drop is certain death
      return false
   else
      return true
   end
end

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


-- check if a provided player is in creative mode
local creative_mode_cache = minetest.settings:get_bool("creative_mode")
function minimal.player_in_creative(plyr)
  -- get the player by name if string
  if (type(plyr) == "string") then
    plyr = minetest.get_player_by_name(plyr)
  end
  -- if player is a player...
  if (minetest.is_player(plyr)) then
    if (minetest.check_player_privs(plyr,"creative") or creative_mode_cache == true) then
      return true
    end
  end

  return false
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
