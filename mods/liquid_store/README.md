Exile mod: liquid_store
=========================

Adds water storage nodes.

Liquids, containers and storage items registered separately.


## Code documentation:
***
##### Storage tables:

* **liquid_store.liquids**

    list of registered liquids, with following format :

            liquid_store.liquids[name] = {
                source = name,
                flowing = flowing version of the liquid,
                force_renew = will it be renewed if we take some,
                }

* **liquid_store.stored_liquids**

    list of registered stored liquid, with following format :

           liquid_store.stored_liquids[name] = {
                nodename : name of the node, ex "tech:clay_water_pot_freshwater"
                source : source, ex "nodes_nature:freshwater_source"
                nodename_empty : container, ex "tech:clay_water_pot"
                dumpable : is the liquid dumpable
            }

##### Registration functions:

* liquid_store.**register_liquid**(source, def)

  e.g. For freshwater:

            liquid_store.register_liquid(
        	   "nodes_nature:freshwater_source",
        	   "nodes_nature:freshwater_flowing",
        	    false)

* liquid_store.**register_stored_liquid**(name, def)

  registers a bucket of liquid (hence the name, "stored liquid")

      e.g. For freshwater Pot:

            liquid_store.register_stored_liquid("tech:clay_water_pot_freshwater",
        	{
                source = "nodes_nature:freshwater_source",
            	nodename = "tech:clay_water_pot_freshwater",
            	empty = "tech:clay_water_pot",
            	tiles = {
            		"tech_water_pot_water.png",
            		"tech_pottery.png",
            		"tech_pottery.png",
            		"tech_pottery.png",
            		"tech_pottery.png",
            		"tech_pottery.png"
            	},
            	node_box = {
            		type = "fixed",
            		fixed = {
            			{-0.25, 0.375, -0.25, 0.25, 0.5, 0.25},
            			{-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375},
            			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125},
            			{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
            			{-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125},
            		}
            	},
            	description = "Clay Water Pot with Freshwater",
        	groups = {dig_immediate = 2}
        })

* liquid_store.**register_scoop_change**(name, replacement)

  >Transforms the named liquid into the replacement when picked up with a pot

  *NOTE: never used in Exile currently, we use custom function instead to preserve meta data from the liquid.*

##### Access/get functions:

* liquid_store.**contents**(nodename)   
    > returns the source (liquid) of a stored liquid
    (nil if node is not a valid stored liquid)


* liquid_store.**get_empty**(nodename)

  >get the empty container of a stored liquid
    (nil if node is not a valid stored liquid)

* liquid_store.**get_sl_def**(nodename,producefake)
    >* get a stored liquid's definition table
    >* if `producefake` is `true`, produces a fake stored liquid def if nodename is not a valid storedliquid, instead of nil.

* liquid_store.**find_stored**(empty, source)
    > * find a stored liquid variant with the provided empty and source  
    >* returns nil if no stored liquid matches given parameters

##### Fill/drain/transfer functions :

* liquid_store.**drain_store**(player, itemstack)

* liquid_store.**fill_store**(player, itemstack, source, returnnil)
    >* uses an 'empty' itemstack and fills it up with the corresponding source
    or stored_liquid
    >* returns filled itemstack on success, return nil otherwise

* liquid_store.**on_use_empty_bucket**(itemstack, user, pointed_thing)
    >* Function for empty buckets to call on_use... as return (so gives item)
    >* preserve source liquid's metadatas

* liquid_store.**on_use_filled_bucket**(itemstack, user, pointed_thing, dump, source, nodename_empty)
    > function for filled buckets to call on_use... as return (so gives item)

* liquid_store.**on_place**(itemstack, placer, pointed_thing)
    > used by both stored liquids and empty buckets


***
Authors of source code
----------------------
Adapted for Exile from buckets from Minetest game:
Kahrl <kahrl@gmx.net> (LGPLv2.1+)
celeron55, Perttu Ahola <celeron55@gmail.com> (LGPLv2.1+)
Various Minetest developers and contributors (LGPLv2.1+)
Heavily modified by the Exile Team


Authors of media (sounds)
----------------------
TPH
(aka tph9677/TubberPupperHusker/TubberPupper/Damotrix)
<damotrixrob@gmail.com>
(marked CC0 1.0)
liquid_store_water_pour.(0-2).ogg
