-- Dewaffler mod
--
-- Provides a command that removes "waffled" terrain around the player who
-- calls it, fixing terrain broken by the long-standing grass spread bug
-- which copied slopes, creating terrain made of one particular type of
-- stairs.
-- The command requires server privs, as it is somewhat resource intensive.


minetest.register_chatcommand("dewaffle", {
	params = "<radius>",
	description = "Resets natural slopes around the player.",
	privs={server=true},
	func = function(name, param)
	   if minetest.check_player_privs(name, {server = true}) then
	      local rad = tonumber(param)
	      if rad and rad ~= 0 then
		 local pos = minetest.get_player_by_name(name):get_pos()
		 local minp = vector.round(vector.subtract(pos,rad))
		 local maxp = vector.round(vector.add(pos,rad))
		 minetest.log("action", name.." ran a dewaffle on "..
		   minp.x.."/"..minp.y.."/"..minp.z.. " through "..
		   maxp.x.."/"..maxp.y.."/"..maxp.z.. ", a radius of "..rad)
		 minetest.chat_send_player(name,"Dewaffling in a radius of "..
					   tostring(rad))
		 naturalslopeslib.area_chance_update_shape(minp, maxp, 0.02)
	      else
		 minetest.chat_send_player(name,
					   "I don't understand a radius of "
					   ..param)
	      end
	   else
	      minetest.chat_send_player(name,
		 "You must have server privs to use this.")
	   end
	end
})
