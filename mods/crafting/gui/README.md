# GUI (Crafting Formspec) Documentation

#### General functions
######

* crafting.**make_crafting_formspec**(`player`, (optional)`cache`)
    > Generates the crafting formspec (common to stations and inventory formspec)
    >* `cache` is player's crafting cache and is optional.It will be get from player if not given.

*  crafting.**set_page**(`player`, `selected_tab_number`)
    > Allow external mod to call this page with specific craft tab

* crafting.**process_receive_fields**(`player`, `formname`, `fields`)
    >* Processes fields in crafting formspec
    >* Returns `true` if something changed, `false` else
    
* crafting.**open_formspec**(`player`, `fs_name`, *(optional)* `cache`)
    >* Mark the formspec as open
    >* `fs_name` is name of the opened formspec
    >* `cache` is optional and will be get for `player` if not given

* crafting.**close_crafting_formspec**(`player`, *(optional)* `cache`)
    >* Gives back items from input panel and updates [cache](#crafting-cache)
    >* `cache` will be get for `player` if not given


#### Stations and tools
######

* crafting.**get_tool_level**(`tool`)
    >Returns level for that tool

* crafting.**generate_tools_list**(`station`, `no_default`)
    > Generates tool list available in `station`. By default a tool is added,
    > to represent crafting with bare hands on a solid flat surface.
    >* `no_default`: if `true`, the default tool will not be added
    >* Returns a list of tool names.

* crafting.**make_tool_formspec**(`player`, (optional)`cache`)
    > Generates current station's formspec for `player`
    > If no station was set, using "nil" as station
    >* `cache` is player's crafting cache and will be get from player if not given.
    > Returns that formspec
    
* crafting.**set_station**(`player`, `station`, `cache`)
    > Set crafting station to given station
    >* `cache` is optional, will be get from player if missing
    >* `station` is a table with following fields:
    >
    >     * `name`: the name(string) of the station (has to be a valid station)
    >     * `title`: string to be displayed above the formspec
    >* `no_default` is to suppress adding the default tool to the tool list

* crafting.**show_station_formspec**(`player`,  (optional)`cache`)
    > Shows current station's formspec for `player`
    > If no station was set, using "nil" as station
    >* `cache` is player's crafting cache and will be get from player if not given.

* crafting.**crafting_item_on_rightclick**(`pos`, `item`, `clicker`, `itemstack`, `pointed_thing`, `no_default_tool`)
    > Opens crafting for spec matching the item's. Usually `item` is a node at position `pos`.
    Except for a few cases crafting should be restricted to be available through nodes.
    > Also adds a default tool to the list of available tools for recipes that only require bare hands and a solid surface.
    >* `no_default_tool`: Set to true to suppress the default tool being added. This makes sense, e.g. if a tool station does not provide a solid flat surface.

<a id="crafting-cache"></a>
#### Player's crafting cache
######

Player's cache is meant to store player's specific informations about recipes, formspec state etc..

* crafting.**register_cache_function**(`name`, `func`)
    > Register a `cache_funcs` function

* crafting.**get_FS_cache**(`player`, *(optional)* `generate`)
    > Gets player's crafting cache  
    > if `generate` is true, generates it if non existent

Cache object has a lot of already registered functions :

* `cache_funcs`:**apply_filters**(`optional_list`)
    > Applies all filters to player's recipes lists in cache (or given in optional_list)

* `cache_funcs`:**set_text_search_to**(`s`)
    > Change Search field and reset formspec accordingly  
    > Return `true` is any change, to trigger formspec redraw

* `cache_funcs`:**get_tool_panel**()
    >  Generate  tool panel formspec

* `cache_funcs`:**get_craft_tabs**()
    >  Generate craft tabs formspec

* `cache_funcs`:**set_craft_tabs**()
    >  Set craft tabs in cache

* `cache_funcs`:**set_tool**()
    >  Set tool in cache, `tool` is optional


* And many other (still to document)
