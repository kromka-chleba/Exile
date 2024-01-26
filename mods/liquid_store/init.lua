

liquid_store = {}
liquid_store.liquids = {}
liquid_store.stored_liquids = {}

--Liquids that it is possible to put in a bucket
function liquid_store.register_liquid(source, flowing, force_renew)
	liquid_store.liquids[source] = {
		source = source,
		flowing = flowing,
		force_renew = force_renew,
	}
end

local on_scoop_change = {}
function liquid_store.register_scoop_change(name, replacement)
   --Transform the named liquid into the replacement when picked up with a pot
   if ( not minetest.registered_nodes[name] ) or
      ( not minetest.registered_nodes[replacement] ) then
      minetest.log("error", "liquid_store: tried to register invalid scoop"..
		   "change: "..name.." vs "..replacement)
      return
   end
   on_scoop_change[name] = replacement
end

function liquid_store.contents(nodename)
   --To be called when you need to know if something's a valid liquid
   --Stores will return their source name; regular nodes will pass through
   local liquiddef = liquid_store.stored_liquids[nodename]
   if liquiddef ~= nil then
      return liquiddef.source
   else
      return nodename
   end
end

-- get a stored liquid's definition table
function liquid_store.get_sl_def(nodename,producefake) -- get stored liquid definition
  local sl_def = liquid_store.stored_liquids[nodename]
  if sl_def then
    return sl_def
  end
  -- allow for getting stored liquids that have the same nodename_empty as nodename
  sl_def = {}
  for _,storeddef in pairs(liquid_store.stored_liquids) do
    if storeddef.nodename_empty == nodename then
      table.insert(sl_def,1,storeddef)
    end
  end
  -- got a table of associated storeddefs
  if #sl_def > 0 then
    return sl_def
  end
  -- return an empty stored_liquid definition
  if producefake == true then
    return {source = "", nodename_empty = "", dump = false} 
  end
end

local function check_protection(pos, user, text)
  local name = (minetest.is_player(user) and user:get_player_name()) or ""
	if minetest.is_protected(pos, name) then
    name = (name ~= "" and name or "A mod")
		minetest.log("action", name.. " tried to " .. text
			.. " at protected position "
			.. minetest.pos_to_string(pos)
			.. " with a bucket")
		minetest.record_protection_violation(pos, name)
		return true
	end
	return false
end

-- handle stacks
local function handle_stacks(player, stack_items, new_item)
   local inv = player:get_inventory()
   if stack_items:get_count() > 1 then
      if inv:room_for_item("main", new_item) then
	 inv:add_item("main", new_item)
      else
	 local pos = player:get_pos()
	 minetest.add_item(pos, new_item)
      end
      return(stack_items:get_name().." "..(stack_items:get_count() - 1))
   else
      return ItemStack(new_item)
   end
end
-- handle punching + finding if it is a node
local function handle_interaction(player, pointed_thing)
  if not pointed_thing then
    return
  end
  if pointed_thing.type == "node" then
    return "node"
  elseif pointed_thing.type == "object" and pointed_thing.ref then
    pointed_thing.ref:punch(player, 1.0, { full_punch_interval=1.0 }, nil)
  end
  return pointed_thing.type
end

local function find_stored(empty, sourcename)
   local stored_name
   for k, v in pairs(liquid_store.stored_liquids) do
      local m = v.nodename_empty
      local s = v.source
      if  m == empty and s == sourcename then
	 stored_name = v.nodename
	 break
      end
   end
   return stored_name
end

-- store metadata into a provided stack (grab liquid)
local function liquid_metadata(pos, oldnode, t_stack)
  local nodedata = minetest.registered_nodes[oldnode.name]
  if (type(nodedata) ~= "table" and type(t_stack) ~= "userdata") then
    return
  end

  -- custom metadata function I created for certain nodes
  if (type(nodedata["_preserve_metadata"]) == "function") then
    local oldmeta = minetest.get_meta(pos)

    return nodedata._preserve_metadata(pos, oldnode, oldmeta, t_stack)
  end
end

function liquid_store.drain_store(player, itemstack)
   local itemname = itemstack:get_name()
   local sdef = liquid_store.get_sl_def(itemname)
   if sdef then
      return handle_stacks(player, itemstack, sdef.nodename_empty)
   else
      return itemstack
   end
end

--Function for empty buckets to call on_use... as return (so gives item)
function liquid_store.on_use_empty_bucket(itemstack, user, pointed_thing)

  if handle_interaction(user, pointed_thing) ~= "node" then
    return
  end

  minetest.check_for_falling(pointed_thing.under) -- install gravity

  -- Check if pointing to a liquid source
  local node = minetest.get_node(pointed_thing.under)
  local name = node.name
  if on_scoop_change[name] then
    name = on_scoop_change[name]
  end
  local liquiddef = liquid_store.liquids[name]
  local storeddef = liquid_store.get_sl_def(name)
  
  -- check protection
  if check_protection(pointed_thing.under, user,
    "take ".. node.name) then
    return
  end

  if liquiddef and
  name == liquiddef.source then -- pointing at a liquid
    -- find a registered stored liquid who has an empty that matches
    -- what we are using and a source that matches our liquid
    local giving_back = find_stored(itemstack:get_name(), name)

    if not giving_back then
   --nothing matches
      return
    end

    local new_wield = handle_stacks(user, itemstack,
      giving_back)

    -- force_renew requires a source neighbour
    local source_neighbor = false
    if liquiddef.force_renew then
     source_neighbor = minetest.find_node_near(pointed_thing.under, 1,
      liquiddef.source)
    end

    if not (source_neighbor and liquiddef.force_renew) then
      minetest.add_node(pointed_thing.under, {name = "air"})
    end

      -- return filled bucket if player is not in creative
    if not (minimal.player_in_creative(user)) then
     liquid_metadata(pointed_thing.under,node,new_wield)
     return new_wield
    end
  elseif storeddef then -- pointing at a stored liquid
    local giving_back = find_stored(itemstack:get_name(),
      storeddef.source)
    if not giving_back then
      --nothing matches
      return
    end
    local new_wield = handle_stacks(user, itemstack,
      giving_back)
    minimal.switch_node(pointed_thing.under,
      {name = storeddef.nodename_empty})

    liquid_metadata(pointed_thing.under,node,new_wield)
    return new_wield
  else -- neither liquid nor a stored liquid
    -- non-liquid nodes will have their on_punch triggered
    local node_def = minetest.registered_nodes[node.name]
    if node_def then
      node_def.on_punch(pointed_thing.under, node, user, pointed_thing)
    end
    return itemstack
   end

end

--Function for filled buckets to call on_use... as return (so gives item)
function liquid_store.on_use_filled_bucket(itemstack, user, pointed_thing, dump, source, nodename_empty)
	-- Must be pointing to node
	if handle_interaction(user, pointed_thing) ~= "node" then
    return
  end
  -- get storeddef or create a fake one
  local storeddef = liquid_store.get_sl_def(itemstack:get_name(),true)
  --local storeddef = liquid_store.stored_liquids[itemstack:get_name()] or {source = "", nodename_empty = "", dump = false}
  -- permit overrides
  source = type(source) == "string" and source or storeddef.source
  nodename_empty = type(nodename_empty) == "string" and nodename_empty or storeddef.nodename_empty
  -- if dump isn't a specified boolean, set to true (can be set to false so liquid stores such as watering cans do not dump their contents)
  if type(dump) ~= "boolean" then
    dump = storeddef.dumpable
    if type(dump) ~= "boolean" then
      dump = true
    end
  end
  -- do not dump an unregistered source!
  if (source == "" or not minetest.registered_nodes[source]) then
    dump = false
  end

  local ppos = pointed_thing.under -- place_pos
  local buildable_to = true -- allow for replacing nil nodes

	local node = minetest.get_node_or_nil(pointed_thing.under)
	local ndef = node and minetest.registered_nodes[node.name]
  local stored
  -- made into a function as it is needed twice
  local function can_rightclick()
    -- if node definition and if player and not sneaking then do rightclick function
    if ndef and not (minetest.is_player(user) and user:get_player_control().sneak) then
      -- Call on_rightclick if the pointed node defines it (do not on_rightclick for liquids or liquid_storage)
      if not (ndef.drawtype == "liquid" or minimal.in_group(ndef,"liquid_storage")) then
        local on_click = minimal.on_rightclick(itemstack, user, pointed_thing)
        if on_click ~= false then
          return on_click
        end
      end
    end
  end

  local click_result = can_rightclick()
  -- prioritize on_rightclick
  if click_result then
    return click_result
  -- check out my cool definition instead
  elseif ndef then
    stored = find_stored(ndef.name, source)
    -- don't remove liquids
    buildable_to = ndef.drawtype ~= "liquid" and ndef.buildable_to or false
  end
  -- check above pos (other node cannot be built to or is not an fillable pot)
  if not (buildable_to or stored) then
    ppos = pointed_thing.above
    ndef = minimal.get_nodedef(ppos)
    -- don't remove liquids
    buildable_to = ndef.drawtype ~= "liquid" and ndef.buildable_to or false
  end
  -- finishing touches if ndef found (verify with the found node!)
  click_result = can_rightclick()
  if click_result then
    return click_result
  elseif ndef then
    -- If pointing at a full liquid store don't dump
    if liquid_store.get_sl_def(node.name) then
      dump = false
    end
  end
  -- we tried, can't do it
  if not (buildable_to or stored) then
    -- do not remove the bucket with the liquid
    return itemstack
  end
  -- prioritize filling up an empty container
  if stored then
    if check_protection(ppos, user, "fill up "..nodename_empty) then
      return
    end
    minimal.switch_node(ppos, {name = stored}, {user, itemstack, pointed_thing})
    return handle_stacks(user, itemstack, nodename_empty)

  -- can replace the node
  -- dump the water ONLY if "dump" is true (if false, do not dump)
  elseif buildable_to and dump then
    if check_protection(ppos, user, "place "..source) then
      return
    end
    minimal.switch_node(ppos, {name = source}, {user, itemstack, pointed_thing})
    minetest.check_for_falling(ppos)

    if (minimal.player_in_creative(user)) then
      return itemstack
    end

    return handle_stacks(user, itemstack, nodename_empty)
  end
end

function liquid_store.on_place(itemstack, placer, pointed_thing, place_name)
  if handle_interaction(placer, pointed_thing) ~= "node" then
    return
  end

  local pos = pointed_thing.under
  local pos_top = pointed_thing.above
  local isliquid = false -- to prevent placement if a liquid that can't be grabbed

  place_name = type(place_name) == "string" and place_name
   or itemstack:get_name()

  local node = minetest.get_node(pos) -- grab a possible liquid if correct
  local nodedata = minetest.registered_nodes[node.name]
  local stored = find_stored(place_name, node.name)
  if (stored) then
    isliquid = true
  end

  local protected = false local top_protected = false
  if (minetest.is_player(placer)) then
     if minetest.is_protected(pos, placer:get_player_name()) then
	protected = true
     end
     if minetest.is_protected(pos_top, placer:get_player_name()) then
	top_protected = true
     end

     if (type(nodedata) == "table" and not placer:get_player_control().sneak
	 and not isliquid
	 and minetest.get_item_group(node.name,"liquid_storage") == 0) then
	if (type(nodedata["on_rightclick"]) == "function") then
	   return nodedata.on_rightclick(pos, node, placer, itemstack,
					 pointed_thing)
      end
    end
  end

  local tndef = minimal.get_nodedef(pos_top) -- top_node definition - check if can be placed
  if not tndef then -- do not place if can't find nodedata
    return
  end

  if stored and ( not protected ) then
    -- if a possible liquid and an empty bucket
    return liquid_store.on_use_empty_bucket(itemstack, placer, pointed_thing)
  elseif (type(minetest.registered_nodes[place_name]) == "table") then

     -- verify if we can place the bucket
     if ( nodedata.buildable_to ~= true or protected == true
	  or isliquid == true ) then -- Can't build here,
	-- attempt to use top to place above/in front of the node
	if tndef.buildable_to == true and not top_protected then
	   pos = pos_top
	else -- Can't place bucket on either top or bottom node, give up
	   return
	end
     end

     if not (minimal.player_in_creative(placer)) then
      itemstack:take_item()
    end
    -- place the bucket
    minimal.switch_node(pos, {name = place_name}, {placer, itemstack, pointed_thing})
    minetest.check_for_falling(pos)
  end

  return itemstack
end


-- Register a new stored liquid...
--    source = name of the source node
--    nodename = name of the new bucket  (or nil if liquid is not takeable)
--    nodename_empty = name of the empty bucket
--    tiles  = textures of the new bucket
--    desc = text description of the bucket item
--    groups = (optional) groups of the bucket item, for example {water_bucket = 1}
--    force_renew = (optional) bool. Force the liquid source to renew if it has a
--                  source neighbour, even if defined as 'liquid_renewable = false'.
--                  Needed to avoid creating holes in sloping rivers.
-- This function can be called from any mod (that depends on liquid_store).
-- Also need to register the liquid itself seperately

function liquid_store.register_stored_liquid(name,def)
  assert(type(name) == "string","liquid_store.register_stored_liquid: expected string for 'name', got "..type(name))
  assert(type(def) == "table","liquid_store.register_stored_liquid: expected definition table, got "..type(def))

	liquid_store.stored_liquids[name] = {
		nodename = name,
		source = def.source,
		nodename_empty = def.empty,
    dumpable = def.dumpable,
	}
  -- remove from node definition
  def.source = nil
  def.empty = nil
  def.dumpable = nil

  local basedef = {
    stack_max = 1,
    liquids_pointable = true,
    paramtype = "light",
    groups = {liquid_storage = 1},
    sounds = minimal.merge_tables(nodes_nature.node_sound_defaults(), def.sounds or {}),
    on_use = function(...)
      return liquid_store.on_use_filled_bucket(...)
    end,
    on_place = function(itemstack, placer, pointed_thing)
      return liquid_store.on_place(itemstack, placer, pointed_thing, name)
    end,
  }
  basedef.drawtype = def.drawtype or def.node_box and "nodebox" or "normal" -- set drawtype to nodebox if node_box is provided
  -- add basedef values
  for index,value in pairs(basedef) do
    if not def[index] then
      def[index] = value
    end
  end
  def.groups = minimal.merge_tables(basedef.groups, def.groups or {})

  minetest.register_node(name,def)
  return minetest.registered_nodes[name]
end




---------------------------------------------------------
--Register liquids
liquid_store.register_liquid(
	"nodes_nature:salt_water_source",
	"nodes_nature:salt_water_flowing",
	false)

liquid_store.register_liquid(
	"nodes_nature:freshwater_source",
	"nodes_nature:freshwater_flowing",
	false)
	--don't force renew or allows an infinite water supply exploit
