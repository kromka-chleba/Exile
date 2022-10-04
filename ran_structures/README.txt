# ran_structures
Random structures. Structure placement API. e.g. placing random ruins, huts etc.

Adapted from mcl_structures from MCL2 (GNU GPLv3), and associated content (mcl_loot, mcl_mapgen_core, mcl_init).


Status:
- proof of concept. Seems to work in principle, but has serious bugs.
- Seems fairly versatile if it can be made to work (e.g. can spawn loot, mobs etc)

Issues:
- code is messy due to ripping it out of another game. May contain redundant/non-functional/buggy code.
- haven't tested if all features it should allow actually work.
- structures are sometimes placing inappropriate foundations (wrong soil types for biome).
- on steep terrain the foundation formation generates unnatural rocky outcrops (possibly an unavoidable problem. Either it must detect flat ground, or create it.)
- can turn off foundation building to avoid above problem, but this seems to make structures extremely rare (for game balance structures should probably be rare anyway).
- current schematics are merely for testing (need balancing, plus many more schems).
- performance? Might be adding a large amount of mapgen lag?? How much does it slow things down? Would another implementation be simpler and faster?
- having multiple structures registered seems to conflict with each other. Only the first registered is generated.????
- Sometimes puts structures in unsuitable places (e.g. half sticking out over a river valley). Due to a foundation building fail??
- Sometimes a lag time between spawning foundation and structure ( a house pops into existence out of nowhere)
- frequently spawns the structure builder without making an actual structure??? (high spawn frequency leads to cane plants floating in mid air, but no structures)
- Ideally this should be made into a game neutral api, with the registered schematics independent.
- Common error. Emerge thread errors::finish gen, couldn't get block generated.
- Haven't tested how well it will do in forests (e.g. will it spawn inside trees?)
- mineclone documentation was a bit limited. Unclear what all parameters actually do.


Other notes:
- schematics can fill up with rocks/plants/dirt if "ignore nodes" are used inside the structures (sometimes looks good, often doesn't)
- smaller schematics might be preferable due to rocky outcrop issue.
- schematics are obvious copy-paste clones. Will need a large number so identical buildings are rarely encountered.
- using random probabilites on schematics can help prevent them all looking like obvious clones.
- Could significantly alter gameplay balance by providing loot and ready made shelter


## ran_structures.register_structure(name,structure definition,nospawn)
If nospawn is truthy the structure will not be placed by mapgen and the decoration parameters can be omitted. This is intended for secondary structures the placement of which gets triggered by the placement of other structures. It can also be used to register testing structures so they can be used with /spawnstruct.

### structure definition
{
	fill_ratio = OR noise = {},
	biomes = {},
	y_min =,
	y_max =,
	place_on = {},
	spawn_by = {},
	num_spawn_by =,
	flags = (default: "place_center_x, place_center_z, force_placement")
	(same as decoration def)
	y_offset =, 	--can be a number or a function returning a number
	filenames = {} OR place_func = function(pos,def,pr)
					-- filenames can be a list of any schematics accepted by ran_structures.place_schematic / minetest.place_schematic
	on_place = function(pos,def,pr) end,
					-- called before placement. denies placement when returning falsy.
	after_place = function(pos,def,pr)
					-- executed after successful placement
	sidelen = int, --length of one side of the structure. used for foundations.
	solid_ground = bool, -- structure requires solid ground
	make_foundation = bool, -- a foundation is automatically built for the structure. needs the sidelen param
	loot = ,
					--a table of loot tables for ran_st_loot indexed by node names
					-- e.g. { ["mcl_chests:chest_small"] = {loot},... }
}
## ran_structures.registered_structures
Table of the registered structure defintions indexed by name.

## ran_structures.place_structure(pos, def, pr)
Places a structure using the mapgen placement function

## ran_structures.place_schematic(pos, schematic, rotation, replacements, force_placement, flags, after_placement_callback, pr, callback_param)
