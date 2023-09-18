

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

local function check_protection(pos, name, text)
	if minetest.is_protected(pos, name) then
		minetest.log("action", (name ~= "" and name or "A mod")
			.. " tried to " .. text
			.. " at protected position "
			.. minetest.pos_to_string(pos)
			.. " with a bucket")
		minetest.record_protection_violation(pos, name)
		return true
	end
	return false
end

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
   local sdef = liquid_store.stored_liquids[itemname]
   if sdef then
      return handle_stacks(player, itemstack, sdef.nodename_empty)
   else
      return itemstack
   end
end

--Function for empty buckets to call on_use... as return (so gives item)
function liquid_store.on_use_empty_bucket(itemstack, user, pointed_thing)

   if pointed_thing.type == "object" then
      pointed_thing.ref:punch(user, 1.0, { full_punch_interval=1.0 }, nil)
      return user:get_wielded_item()
   elseif pointed_thing.type ~= "node" then
      -- do nothing if it's neither object nor node
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
   local item_count = user:get_wielded_item():get_count() -- Unused?
   local storeddef = liquid_store.stored_liquids[name]

   if liquiddef ~= nil
      and name == liquiddef.source then
      if check_protection(pointed_thing.under, user:get_player_name(),
			  "take ".. node.name) then
	 return nil
      end

      --find a registered stored liquid who has an empty that matches
      -- what we are using and a source that matches our liquid
      local giving_back = find_stored(itemstack:get_name(), name)

      if not giving_back then
	 --nothing matches
	 return nil
      end

      local new_wield = handle_stacks(user, user:get_wielded_item(),
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

   elseif storeddef ~= nil then
      if check_protection(pointed_thing.under, user:get_player_name(),
			  "take ".. node.name) then
	 return nil
      end
      local giving_back = find_stored(itemstack:get_name(),
				      storeddef.source)
      if not giving_back then
	 --nothing matches
	 return nil
      end
      local new_wield = handle_stacks(user, user:get_wielded_item(),
				      giving_back)
      minimal.switch_node(pointed_thing.under,
			  {name = storeddef.nodename_empty})

      liquid_metadata(pointed_thing.under,node,new_wield)
      return new_wield
   else
      -- non-liquid nodes will have their on_punch triggered
      local node_def = minetest.registered_nodes[node.name]
      if node_def then
	 node_def.on_punch(pointed_thing.under, node, user, pointed_thing)
      end
      return user:get_wielded_item()
   end

end

--Function for filled buckets to call on_use... as return (so gives item)
function liquid_store.on_use_filled_bucket(source,nodename_empty,itemstack, user, pointed_thing, dump)
	-- Must be pointing to node
	if pointed_thing.type ~= "node" then
		return
	end
  -- if dump isn't a specified boolean, set to true (so watering cans do not dump their contents)
  if (type(dump) ~= "boolean") then
    dump = true
  end
  -- do not dump an unregistered source!
  if (type(source) ~= "string") then
    source = ""
  end
  if not (minetest.registered_nodes[source]) or source == "" then
    dump = false
  end

	local node = minetest.get_node_or_nil(pointed_thing.under)
	local ndef = node and minetest.registered_nodes[node.name]

	-- Call on_rightclick if the pointed node defines it (do not on_rightclick for liquids)
  if (type(ndef) == "table" and minetest.is_player(user)) then
     if (type(ndef["on_rightclick"]) == "function"
	 and ndef.drawtype ~= "liquid" and
	 not user:get_player_control().sneak) then
      return ndef.on_rightclick(pointed_thing.under, node, user, itemstack)
    end
  end

	local lpos
	local stored = find_stored(node.name, source)
	-- Check if pointing to a buildable node
	if ndef.drawtype ~= "liquid" and ( ndef and ndef.buildable_to )
	   or stored then
		-- buildable; replace or fill the node
		lpos = pointed_thing.under
	else
		-- not buildable to; place the liquid above
		-- check if the node above can be replaced

		lpos = pointed_thing.above
		node = minetest.get_node_or_nil(lpos)
		local above_ndef = node and minetest.registered_nodes[node.name]

		if not above_ndef or not above_ndef.buildable_to then
			-- do not remove the bucket with the liquid
			return itemstack
		end
	end

	if check_protection(lpos, user
			and user:get_player_name()
			or "", "place "..source) then
		return
	end
	if stored then -- Dump contents into liquid store
	   minimal.switch_node(lpos, {name = stored}, {user, itemstack, pointed_thing})

	   return handle_stacks(user, itemstack, nodename_empty)
	end

  -- dump the water ONLY if "dump" is true (if false, do not dump)
  if dump then
    minimal.switch_node(lpos, {name = source}, {user, itemstack, pointed_thing})

    minetest.check_for_falling(lpos)

    if (minimal.player_in_creative(user)) then
      return
    end

    return handle_stacks(user, itemstack, nodename_empty)
  end
end

function liquid_store.on_place(place_name, itemstack, placer, pointed_thing)
  if (pointed_thing.type ~= "node" or type(itemstack) ~= "userdata") then
    return
  end
  if (type(place_name) ~= "string") then
    itemstack:get_name()
  end

  local pos = pointed_thing.under
  local pos_top = pointed_thing.above

  local isliquid = false -- to prevent placement if a liquid that can't be grabbed

  local node = minetest.get_node(pos) -- grab a possible liquid if correct
  local nodedata = minetest.registered_nodes[node.name]
  local stored = find_stored(itemstack:get_name(), node.name)
  if (stored) then
    isliquid = true
  end
  if (type(nodedata) == "table") then
    if (nodedata.drawtype == "liquid") then
      isliquid = true
    end
  else -- do not place if can't find nodedata
    return
  end

  if (minetest.is_player(placer)) then
     if (minetest.is_protected(pos, placer:get_player_name())
	 or minetest.is_protected(pos_top, placer:get_player_name()) ) then
      return
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

  local top_node = minetest.get_node(pos_top) -- check if can be placed
  local top_nodedata = minetest.registered_nodes[top_node.name]

  if (type(top_nodedata) ~= "table") then -- do not place if can't find nodedata
    return
  end

  if stored then
    -- if a possible liquid and an empty bucket
    return liquid_store.on_use_empty_bucket(itemstack, placer, pointed_thing)
  elseif (type(minetest.registered_nodes[place_name]) == "table") then
    -- verify if can place bucket
    if (nodedata.buildable_to ~= true and top_nodedata.buildable_to == true or isliquid == true) then
      -- if any of the above is correct, place above the node
      pos = pos_top
    elseif (nodedata.buildable_to ~= true and top_nodedata.buildable_to ~= true) then
      return -- can't place bucket
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

function liquid_store.register_stored_liquid(source, nodename, nodename_empty, tiles, node_box, desc, groups)

	liquid_store.stored_liquids[nodename] = {
		nodename = nodename,
		source = source,
		nodename_empty = nodename_empty
	}


	if nodename ~= nil then
    groups.liquid_storage = 1 -- contains liquid

		minetest.register_node(nodename, {
			description = desc,
			tiles = tiles,
			drawtype = "nodebox",
			node_box = node_box,
			paramtype = "light",
			stack_max = 1,
			liquids_pointable = true,
			groups = groups,
			sounds = nodes_nature.node_sound_defaults(),

			on_use = function(...)
				return liquid_store.on_use_filled_bucket(source,nodename_empty,...)
			end,

      on_place = function(...)
        return liquid_store.on_place(nodename,...)
      end,
		})

	end
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
