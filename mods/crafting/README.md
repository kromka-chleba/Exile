# crafting

Adds semi-realistic crafting with unlockable recipes to Minetest, and removes
the craft grid.

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

For example, you can't have the following recipe as `default:wood` could
be used twice: `default:wood, group:wood`.


## API

#### Groups

* crafting.get_group_stats(grouptag)
    *returns table of details relating to that group

* crafting.get_group_items(g_name)
    * returns a lits of all registered items being in that group
    *`g_name` is the group's name

#### Recipes

* crafting.register_type(name, label, icon_item_name, sound)
	* Register a type `type` used for tabs and recipes sorting
        * `name`   - name of the type
        * `label` - label of the type
        * `icon_item_name`  used to be displayed in tab in crafting formspec
        * `sound` - sound made when we craft this type

* crafting.register_recipe(def)
	* Returns id.
	* `def` a table with the following fields:
		* `type`   - one of the registered types.
		* `output` - the result of the craft, eg: `default:stone 3`.
		* `items`  - A list of ingredients, eg: `{"stone", "wood 3"}`.
		* `level`  - level of station required.
		* `always_known` - If `true`, this recipe will never need to be unlocked.
        * `replace`
        * `sound`
        * `_display` - string of image to display in recipe panel

* crafting.get_recipe(param)
	* Get recipe by ID if `param` is a number,
    * Get recipe per output if `param` is a string

* crafting.get_unlocked(name)
	* `name` is the player's name
	* Returns a dictionary of recipe output to boolean.

* crafting.lock_all(name)
    * `name` is the player's name

* crafting.unlock(name, v)
	* `name` is the player's name
	* `v` is a single output or list of outputs

#### Crafting

* crafting.register_on_craft(func)
  * register a function to be called at each craft

* crafting.set_item_hashes_from_list(inv, listname, item_hash)
	* Iterates through the list and adds or updates entries in item_hash
	  representing the number of items for each names and group.

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

* crafting.perform_craft(name, inv, listname, outlistname, recipe)
	* Will try to take itemsfrom `listname` and put output in the `outlistname` list in `inv`.
	* Returns `true` on success.

* crafting.check_inputs (recipe, item_hash)
    * Checks the state of `recipe` using `itemhash` to craft it
    * Returns:
        * `craftable`, a number equal to
            * 1 if all required items are in set_item_hash
            * 2 if some of them are
            * 0 if none of them are in item_hash
        * `items` - a table with
            * index : item's name
            * value : a list with those parameters :
                * `name` = name of the item
                * have = the number we have in item_hash
                * need = the number we need for the recipe,
                * partial = `true` if we have some of the needed
                * available = `true` if we have more than needed
                * short = description of the item

* crafting.is_craftable (recipe, level, unlocked, item_hash)
    * Returns `true` if we have all required items for the `recipe` in `item_hash`
    * `recipe` - recipe's info (def table)
    * `item_hash` - a table with keys being item names or group names (eg: `group:wood`)
                    and the value being the number required.
    * `unlocked`  - a list of outputs the player has unlocked.

* crafting.get_all(type, level, item_hash, unlocked)
    * Gets all unlocked recipes to display
    * Returns a table with following format :
        t[i] = {
        `recipe`    - recipe def table
        `items`     - as described in crafting.check_inputs
        `craftable` - as described in crafting.check_inputs
        `displayed` - true if recipe should be displayed in GUI
	* `item_hash` - a table with keys being item names or group names (eg: `group:wood`) used to say feel items and craftable info.
	                and the value being the number required.
	* `unlocked`  - a list of outputs the player has unlocked.
    
* crafting.get_all_for_player(player, type, level)
	* Returns result of crafting.get_all called with
        * "main" player's inventory list as item_hash
        * unlocked recipe list for that player

* crafting.update_craftable_state(recipe, item_hash)
    *`result` being a table with forme of crafting.get_all's result
    *`item_hash` a list of items and number used to check if recipe is still craftable or not
    * Modifies and returns `result` with new craftable and items info in table

* function crafting.sort_craftable_recipes(t)
    * `t` a recipe list with crafting.get_all return format
    * Returns 2 lists : craftable and uncraftable table with same format

#### Filter (search field)

* crafting.apply_search(recipe, search, lang_code, combine)
    * Modifies displayed setting of recipes in recipe_list
    *`recipe` is a recipe def table
    *`search` is a string or a table of strings
    *`lang_code` is the language of the player
    *'combine' is an optional parameter :
        used in case of multiple criteria (if search is a table)
        * `true` means a displayed recipe will remaine displayed anyway
        * `false` (default) means we will erase previous displayed setting
    * Return `true` is search was found, `false` else
    
* crafting.apply_search_to_list (recipe_list, search, lang_code, combine)
    * same as crafting.apply_search, but `recipe_list` is a list of `recipe`
    
#### GUI (inventory formspec and statin formspec)

* crafting.crafting_item_on_rightclick(pos,node,clicker, itemstack,pointed_thing)
    * opens crafting for spec matching the node's name
    
* crafting.refresh_recipes_FS(player)
    * refreshes the recipe panel cache in crafting GUI.

#### unused and commented in Exile

* crafting.make_result_selector(player, type, level, size, context)
    *not present in code anymore*
	* Generates a paginated form which a search box.
	* `type`    - craft type.
	* `size`    - how many slots to show on a page.
	* `context` - server-side storage between show and submit, can be `{}`.
		* `crafting_page` - page to show

* crafting.result_select_on_receive_results(player, type, level, context, fields)
	* Handles form submissions for the result selector.
	* Returns `true` if the formspec should be shown again.

* crafting.make_on_rightclick(type, level, inv_size)
	* Returns a function to be used as on_rightclick for node work stations.

-----------------------------------------------------------------------------

* crafting.create_async_station(name, type, level, def_inactive, def_active)
	* Makes a station which players put items into and then leave to craft.
	* Registers two nodes - inactive and active versions of the station.

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
