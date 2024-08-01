-- minimal/protection.lua
--
-- This may need to moved someplace else eventually.

local S=minimal.S
creative = creative

local __nail_use_count = 3

local __open_access_list={}

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

function minimal.protection_key_click( itemstack, clicker, pointed_thing)
	if not pointed_thing or pointed_thing.type ~= 'node' then
		return
	end
	local pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
	local pt_meta = minetest.get_meta(pt_pos)
	local player_name = clicker:get_player_name()
	local pt_owner = pt_meta:get_string('owner')
	if pt_owner and pt_owner ~= player_name then
		return
	end

	local fs_list ="";

	local list_json = pt_meta:get_string("access_list")
	if list_json and list_json ~= '' then
		local access_list = minetest.parse_json(list_json)
		if access_list and #access_list > 0 then
			for i,name in ipairs(access_list) do
				fs_list = fs_list .. name
				if i < #access_list then
					fs_list =fs_list .. ","
				end
			end
		end
	end

	if fs_list ~= '' then
			__open_access_list[player_name] = { pos = pt_pos }
			local formspec = "formspec_version[6]"
				.. "size[10.5,4]"
				.. "box[0.4,0.9;9.8,1.6;red]"
				.. "label[4.3,0.5;"..S("Access List").."]"
				.. "dropdown[1.1,1.35;4.8,0.7;access_list;" 
					.. fs_list .. ";1;false]"
				.. "button_exit[6.6,1.3;3,0.8;Delete;"..S("Delete").."]"
				.. "button_exit[3.7,2.8;3,0.8;Close;"..S("Close").."]"
			minetest.show_formspec(player_name, "protection:access_list", formspec)
	else
		minetest.chat_send_player(player_name, S("Access list empty.")) 
	end

end

minetest.register_on_player_receive_fields(
   function(player,formname,fields)
      if formname ~= "protection:access_list" then
	 return
      end
      local player_name=player:get_player_name()
      if fields.Delete and  __open_access_list
	    and __open_access_list[player_name]
	    and __open_access_list[player_name].pos then
	 local pt_pos = __open_access_list[player_name].pos
	 local pt_meta = minetest.get_meta(pt_pos)
	 local list_json = pt_meta and pt_meta:get_string("access_list")
	 local access_list = {}
	 if list_json and list_json ~= '' then
	    access_list = minetest.parse_json(list_json)
	    for i,granted in ipairs(access_list) do
	       if fields.access_list == granted then
		  access_list[i] = nil
	       end
	    end
	    minetest.chat_send_player(player_name,
				      S("Deleted @1 from access list.",
					fields.access_list))
	 end
	 -- write out json
	 if #access_list > 0 then
	    pt_meta:set_string("access_list",
			       minetest.write_json(access_list))
	 else
	    pt_meta:set_string("access_list", "")
	 end
      end
      __open_access_list[player_name] = nil
      return true
   end
)

function minimal.protection_key_use( itemstack, user, pointed_thing )
	if not pointed_thing or pointed_thing.type ~= "node" then return end
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
						minetest.chat_send_player(owner, S("@1 already has access", key_owner))
						add_name = false
						break
					end
				end
			end
			if add_name then
				table.insert(access_list, key_owner)
				pt_meta:set_string("access_list", minetest.write_json(access_list))
				minetest.chat_send_player(owner, S("@1 granted access", key_owner))
			end
		else
			minetest.chat_send_player(owner, S("Can't grant access to items you don't own"))
		end
	end
end

function minimal.protection_nail_use( itemstack, user, pointed_thing )
	if not pointed_thing or pointed_thing.type ~= "node" then return end
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
      minimal.infotext_set_new(pt_pos, pt_meta)
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
	minimal.infotext_set_new(pos, meta)
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


