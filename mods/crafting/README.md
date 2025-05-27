# crafting

Adds semi-realistic crafting with unlockable recipes to Minetest,
Craft grid becomes otional

Based on rubenwardy's mod
Modified for Exile  
**WARNING : not compatible with original mod anymore**

License: LGPLv2.1+

![Screenshot](screenshot.png)

## Image Licenses

rubenwardy (CC BY-SA 3.0):
  crafting_slot_*.png

Neuromancer (CC BY-SA 3.0):
  crafting_furnace_*.png

BlockMen (CC BY-SA 3.0):
  gui_*.png

paramat (CC BY-SA 3.0)
  creative_trash_icon.png  (derived from a texture by kilbith, same license)

## Limitations

Any recipes must be designed such that any particular item can only be used
as one of the ingredients.

For example, you can't have the following recipe, as `default:wood` could
be used twice: `default:wood, group:wood`.

## API

### Groups

* crafting.get_group_items(g_name)
    * returns a lits of all registered items being in that group
    * `g_name` is the group's name

* crafting.get_group_stats(grouptag)
    * Returns a table of fields included in string grouptag

    * `grouptag` is a string to be used in recipes
    Format is group:<groupname>,<groupnumcondition>,<unit>
        * `groupname` is mandatory name of the group
        * `groupnumcondition` (optional) is required group's number (3,8) or condition (>2 or <6)
        * `unit` (optional) is the unit required. Ex: "pot"

    Ex: "group:freshwater,1/pot>"

    * Following fields are created:
        * `name` the name of the group (groupname)
        * `tag` is "group:" .. name
        * `num_cmd` (can be nil !) condition ">" or "<". if no command, defautl condition is "="
        * `num` (can be nil !) required group number
        * `correct`  is a function returning `true` if number condition is verified, `false` else.
            Always returns `true` if no number to test.
        * `desc` is generated if group had no desc
        * `unit` if present


### Crafting types

* crafting.register_type(name, label, icon_item_name, sound)
	* Register a type `type` used for tabs and recipes sorting
        * `name`  - name of the type in code
        * `label` - label of the type displayed in game. Translated
        * `icon_item_name` - used to be displayed in tab in crafting formspec
        * `sound` - sound made when we craft this type
        * `recipes` - array of possible recipes for that crafting type, assigned to {} at registration.

* crafting.reset_craft_types()
    * Deletes all registered craft types

* crafting.is_type_registered(name)
    * Returns `true` if type is already registered, `false` else.

* crafting.get_type(name)
    * Returns the type's table
    See `crafting.register_type` for the fields

* crafting.get_recipes_by_type(name)
    * Returns crafting.get_type(name).recipes
    *  `nil` if `name` is not a registered type

* crafting.get_registered_types_names()
    * Returns an array of all registered craft types names

### Recipes

* crafting.register_recipe(def)
	* Returns id.
	* `def` a table with the following fields:
		* `type`   - one of the registered types.
		* `output` - the result of the craft, eg: `default:stone 3`.
		* `items`  - A list of ingredients, eg: `{"stone", "wood 3"}`.
		* `level`  - level of station required.
		* `always_known` - If `true`, this recipe will never need to be unlocked.
        * `replace`
        * `sound` - sound to be played when we use that recipe. Overrides default crafting type sound.
        * `_display` - string of image to display in recipe panel

* crafting.get_recipes()
    * Get global recipes table, with id as index

* crafting.get_recipe(id)
	* Get recipe by ID

* crafting.get_unlocked(name)
	* `name` is the player's name
	* Returns a dictionary of recipe output to boolean.

* crafting.lock_all(name)
    * `name` is the player's name

* crafting.unlock(name, v)
	* `name` is the player's name
	* `v` is a single output or list of outputs

### Player_recipes

* crafting.get_player_recipes(player_name, ctype)
    * Returns a list of `player_recipe` table for `ctype` as craft type
    * `player_recipe` is a table with following fields:
        * `recipe`: the common recipe's def table
        * `it_details`: detailled list of items:
            * index : item's name
            * value : a list with those parameters :
                * `name` = name of the item
                * `short` = description of the item to be displayed in recipe panel
                * `need` = the number we need for the recipe
                -- if itemhash is given (else added in update_item function)
                * `have` = the number we have in item_hash
                * `available` = `true` if we have more than needed
        * `craftable`: craftable state, boolean
        * `displayed`: true if recipe should be displayed in GUI
        * `to_take`, `possible`, `to_move` fields can be added later
        * has following function in metatable.

#### Object `player_recipe` functions

* update_craftable_state (self, item_hash)
    * Check ingredients in `item_hash` to update `craftable` and `to_take` fields for that recipe
    * `craftable` is boolean (craftable or not)
    * `to_take` is a list of items to take to craft it
    * WARNING: only check inputs, do not check new unlocked recipes

* update_possible_state (self, item_hash)
    * same as `update_craftable_state` but with `possible` and `to_move` fields
    * `to_move` is a list of itmes to take in `item_hash` to make the recipe craftable (if `possible`)

* available_level (self, p_level)
    * returns `true` if recipe's level is <= `p_level`

### Craft (api.lua)

* crafting.register_on_craft(func)
  * register a function to be called at each craft

* crafting.set_item_hash_from_list(inv, listname, item_hash)
	* Iterates through the list and adds or updates entries in item_hash
	  with follwing format:
      {[`item name`] = {
        `count` = item count in inventory
        `groups` = groups from item's definition table
      }

* crafting.get_item_hash(pInv, inv_lists)
    * Returns an item_list from all selected inv list
    * Like crafting.set_item_hash_from_list but mixing all lists given in inv_list as one list.

* crafting.can_craft(name, ctype, level, recipe)
    * Returns `true` if
        * `recipe` is unlocked
        * and its type matchs with `ctype`
        * and the level of the recipe is <= to `level`


* crafting.find_required_items_inv(inv, listname, recipe)
    * `listname` can be an inventory list, or a list of inventory lists`
    * Returns a list of what was found per list
    {[list1] = {stack1, stack2, ...}, [list2] = {stack1, stack2}, ...}
    * Returns nil if not found or not enought for recipe


* crafting.find_required_items(inv, listname, recipe)
    * `listname` can be an inventory list, or a list of inventory lists`
    * Returns a list of what was found all lists together :
    {stack1, stack2, ...}
    * Returns nil if not found or not enought for recipe

* crafting.has_required_items(inv, listname, recipe)
	* Returns `true` if the `"main"` list in `inv` contains the required items.

* crafting.transfer_items(player, to_list, from_list, item_list)
    * Transfers all items from `item_list` arraw of items from `from_list` to `to_list` in player inventory's, if possible
    * Returns remaining item_list if they didn't all fit in

* crafting.perform_craft(name, inv, listname, outlistname, p_recipe, ctype, craft_count)
	* Will try to take itemsfrom `listname` and put output in the `outlistname` list in `inv`.
    * `p_recipe` is a player_recipe instance
    * `ctype` is a crafting type
    * `craft_count` is the number of output I have to craft
	* Returns `true` on success.


### Filter (search field)

* crafting.get_search_result(p_recipe, search, lang_code, combine)
    * Modifies displayed setting of recipes in recipe_list
    * `p_recipe` is a player_recipe
    * `search` is a string or a table of strings
    * `lang_code` is the language of the player
    * `combine` is an optional parameter :
        used in case of multiple criteria (if search is a table)
        - `true` means any of the string in the search table has to be found (OR)
        - `false` (default) means all of them has to match (AND)
        Return `true` is search was found, `false` else

### GUI (inventory formspec and station formspec)

* crafting.make_crafting_formspec(player)
    * Generates crafting formspec (common to stations and inventory formspec) and crafting cache if non existent.

* crafting.close_crafting_formspec(player, generate)
    * Closes crafting formspec and clear cache
    * if `generate` is true, then generate new cache if player's cache is nil
      else, send an error log.

* crafting.process_receive_fields(player, formname, fields)
    * Processes fields in crafting formspec
    * Returns `true` if something changed, `false` else

#### Stations and tools

* crafting.get_tool_level(tool)
    * Returns level for that tool

* crafting.generate_tools_list(station)
    * Generates tool list to display for `station`

* crafting.make_tool_formspec(player, cache)
    * generates current station's formspec for `player`
    * `cache` is optional, would be regenerated from player if `nil`
    * Returns that formspec

* crafting.show_station_formspec(player, player_name)
    * Shows current station's formspec for `player`

* crafting.crafting_item_on_rightclick(pos,node,clicker, itemstack,pointed_thing)
    * opens crafting for spec matching the node's name

#### Object `cache` functions

* crafting.register_cache_function (name, func)
    * Register a `cache` function

* crafting.get_FS_cache(player)
    * Gets player's crafting cache, or generates it if nil

* apply_filters(self, optional_list)
    * Applies all filters to player's recipes lists in cache (or given in optional_list)

* set_text_search_to(self, s)
    * change Search field and reset formspec accordingly
    * return `true` is any change, to trigger formspec redraw

* many others not documented yet...


## Development


**Installation:**

```sh
# Dependencies for linter and test framework
sudo apt install luarocks
sudo luarocks install luacheck
sudo luarocks install busted

# Set up git hook to disallow commiting when linter or tests fail
./utils/setup.sh
```
