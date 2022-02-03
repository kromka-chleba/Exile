--suicide.lua
--A chat command to allow users to start over

local function suicide_confirm (name, message)
	local player=minetest.get_player_by_name(name)
	local pmeta=player:get_meta()
	local confirm=pmeta:get_int("suicide:confirm")
	if confirm ~= 1 then
		return false
	end

	if message == 'Yes' then
		minetest.chat_send_all(name .. " slipped on a banana peel and broke their neck.")
		player:set_hp(0);
	else
		minetest.chat_send_player(name, "You've come to your senses and decided to keep trying")
	end
	pmeta:set_int("suicide:confirm",0);
	return true
end


local function suicide (name, param) 
	local player=minetest.get_player_by_name(name)
	local pmeta=player:get_meta()
	minetest.chat_send_player(name, "Are you sure?  Reply with: Yes")
	pmeta:set_int("suicide:confirm",1)
end

minetest.register_chatcommand("suicide",{
	privs = {
		interact = true,
	},
	func = suicide
})
minetest.register_chatcommand("killme",{
	privs = {
		interact = true,
	},
	func = suicide
})
minetest.register_chatcommand("respawn",{
	privs = {
		interact = true,
	},
	func = suicide
})


minetest.register_on_chat_message(suicide_confirm)

