return
   {
      ["lz"] = {
	 name = "Landing zone",
	 schem = "",
	 size = vector.new(50,1,50),
	 start = vector.new(0,0,0),
	 location = vector.new(0,0,0),
	 entry = function(player, name)
	    -- examples
	    minetest.set_privs(name, { interact = false })
	    player:set_armor_groups({ immortal = 1})
	 end,
	 exit = function(player, name)
	    minetest.set_privs(name, { interact = true })
	    player:set_armor_groups({ immortal = 0})
	 end,
      },
      [1] = {
	 name = "Movement",
	 schem = "movement",
	 size = vector.new(46, 28, 22),
	 start = vector.new(5,3,16),
	 location = vector.new(80,0,800),
	 exit = function(player, name)
	    minetest.chat_send_player(name, "Area complete")
	 end,
      },
      [2] = nil
   }
