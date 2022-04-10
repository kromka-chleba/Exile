-- minimal/protection.lua
--
-- 

-- Set owner for protected items.
function minimal.protection_after_place_node( pos, placer, itemstack, pointed_thing )
	local pn = placer:get_player_name()
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", pn)
	minimal.set_infotext(pos)
	return (creative and creative.is_enabled_for and creative.is_enabled_for(pn))
end
