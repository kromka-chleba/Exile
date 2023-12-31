-- minimal/protection.lua
--
-- This may need to moved someplace else eventually.

S=minimal.S
creative = creative

local __nail_use_count = 3


function minimal.protection_is_ownable( pointed_thing, pt_pos )
	if pointed_thing.type == 'node' then
		if pt_pos == nil then
			pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
		end
		local pt_node=minetest.get_node(pt_pos)
		if not (pt_node.name == 'tech:stick'
			or minetest.get_item_group(pt_node.name,
						   'flora') > 0
			or minetest.get_item_group(pt_node.name,
						   'unclaimable') > 0
		) then
			return true
		else
			return false
		end
	end
end


function minimal.protection_key_use( itemstack, user, pointed_thing )
	local owner = user:get_player_name()
	local key_owner_test = itemstack:get_meta():get_string("creator")
	local playsound = false
	local pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
	if minimal.protection_is_ownable(pointed_thing, pt_pos) then
		local pt_meta=minetest.get_meta(pt_pos)
		local pt_owner = pt_meta:get_string('owner')
		if pt_meta:contains('owner') and pt_owner == owner then
			local key_owner = itemstack:get_meta():get_string("creator")
			local access_list = {}
   			local list = pt_meta:get_string("access_list")
			local add_name = true -- Assume we're adding the name
   			if list and list ~= "" then
				access_list = minetest.parse_json(list)
				for _,name in ipairs(access_list) do
					if name == key_owner then
						minetest.chat_send_player(owner, key_owner .. " already has access")
						add_name = false
						break
					end
				end
			end
			if add_name then
				table.insert(access_list, key_owner)
				pt_meta:set_string("access_list", minetest.write_json(access_list))
				minetest.chat_send_player(owner, key_owner .. " granted access")
			end
		else
			minetest.chat_send_player(owner,"Can't grant access to items you don't own")
		end
	end
end

function minimal.protection_nail_use( itemstack, user, pointed_thing )
	local owner = user:get_player_name()
	local playsound = false
	local pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
	if minimal.protection_is_ownable(pointed_thing, pt_pos) then
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


