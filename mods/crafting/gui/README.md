# GUI (Crafting Formspec) Documentation

#### General functions
######

* crafting.**make_crafting_formspec**(`player`)
    > Generates the crafting formspec (common to stations and inventory formspec)

*  crafting.**set_page**(`player`, `selected_tab_number`)
    > Allow external mod to call this page with specific craft tab

* crafting.**process_receive_fields**(`player`, `formname`, `fields`)
    >* Processes fields in crafting formspec
    >* Returns `true` if something changed, `false` else

* crafting.**refresh_recipes_FS**(`player`)
    > Let other mods update recipes states to be displayed on re-opening of inv formspec

* crafting.**close_crafting_formspec**(`player`, *(optional)* `cache`)
    >* Gives back items from input panel and updates [cache](#crafting-cache)
    >* `cache` will be get for `player` if not given


#### Stations and tools
######

* crafting.**get_tool_level**(`tool`)
    >Returns level for that tool

* crafting.**generate_tools_list**(`station_name`)
    > Generates tool list available in `station_name`

* crafting.**make_tool_formspec**(`player`, `cache`)
    > Generates current station's formspec for `player`
    >* `cache` is optional, would be regenerated from player if `nil`
    >* Returns that formspec

* crafting.**show_station_formspec**(`player`, `player_name`)
    > Shows current station's formspec for `player`

* crafting.**crafting_item_on_rightclick**(`pos`,`node`,`clicker`, `itemstack`,`pointed_thing`)
    > Opens crafting for spec matching the node's name

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
