-- minimal/protection.lua
--
-- This may need to moved someplace else eventually.

S=minimal.S
creative = creative

local __nail_use_count = 3

function minimal.protection_nail_use( itemstack, user, pointed_thing )
	local owner = user:get_player_name()
	local playsound = false
	if pointed_thing.type == 'node' then
		local pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
		if minimal.click_count_ready(owner, "nail", pt_pos, __nail_use_count) then
			local pt_node=minetest.get_node(pt_pos)
			if not (pt_node.name == 'tech:stick'
				or minetest.get_item_group(pt_node.name,
							   'flora') > 0
				or minetest.get_item_group(pt_node.name,
							   'unclaimable') > 0
			) then
				local pt_meta=minetest.get_meta(pt_pos)
				if not pt_meta:contains('owner') then
					pt_meta:set_string("owner", owner)
					pt_meta:set_string('nailed', owner)
          -- take nails if player isn't in creative
          if not (minimal.player_in_creative(user)) then
            itemstack:take_item()
          end
					minimal.infotext_merge(pt_pos, nil, pt_meta)
					-- play hammering sound
					playsound = true
				end
			end
		end
	end
	return itemstack, playsound
end


-- Set owner for protected items.
function minimal.protection_after_place_node( pos, placer, itemstack, pointed_thing )
	local pn = placer:get_player_name()
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", pn)
	minimal.infotext_merge(pos,nil,meta)
	return minimal.player_in_creative(placer)
end

function minimal.protection_on_dig(pos,oldnode,digger)
   -- Handles removal of nails from nodes protected by them
   local meta = minetest.get_meta(pos)
   if not meta:contains('nailed') then return end
   local owner = meta:get_string('owner')
   if owner == "" then
      minetest.log("error", "Blank owner for nailed item "..oldnode.name..
		   " at "..minetest.pos_to_string(pos))
   end
   local digname = digger and digger:get_player_name() -- nil or "" if non-player
   if owner == digname then
      local def = minetest.registered_nodes[oldnode.name]
      if not def or (def.can_dig and not def.can_dig(pos, digger) ) then
	 return -- undefined node, or not allowed to dig (like a full backpack)
      end
      --give digger back the nails (if they're not in creative)
      if not (minimal.player_in_creative(owner)) then
        local inv = digger:get_inventory()
        if inv:room_for_item("main", 'tech:nails') then
          inv:add_item("main",'tech:nails')
        else
	  minimal.warn_inv_full(digger)
          minetest.add_item(pos, 'tech:nails')
        end
      end
      meta:set_string('owner', "")
      meta:set_string('nailed', "")
   end
end


