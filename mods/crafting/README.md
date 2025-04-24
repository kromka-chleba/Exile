# crafting

Adds semi-realistic crafting with unlockable recipes to Minetest, and removes
the craft grid.

By rubenwardy  
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

### Groups

* crafting.get_group_table(group_name)
    * Returns list of item names by group

* crafting.get_group_stats(grouptag)
    * Returns a table of fields included in string grouptag

    * `grouptag` is a string to be used in recipes
    Format is group:<groupname>,<groupnumcondition>,<desc>
        * `groupname` is mandatory name of the group
        * `groupnumcondition` (optional) is required group's number (3,8) or condition (>2 or <6)
        * `desc` (optional) is a custom description  to display in recipe

    Ex: "group:flammable,1,Flammable>"

    * Following fields are created:
        * `name` the name of the group (groupname)
        * `tag` is "group:" .. name
        * `num_cmd` (can be nil !) condition ">" or "<". if no command, defautl condition is "="
        * `num` (can be nil !) required group number
        * `correct`  is a function returning `true` if number condition is verified, `false` else.
        Always returns `true` if no number to test.


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
    * Returns `true` if type is already registered, `false`else.

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

* crafting.get_recipe(id)
	* Get recipe by ID

* crafting.get_unlocked(name)
	* `name` is the player's name
	* Returns a dictionary of recipe output to boolean.

* crafting.unlock(name, v)
	* `name` is the player's name
	* `v` is a single output or list of outputs

* crafting.get_all_for_player(player, type, level)
	* Returns a list of results, each a table
		* `items` - a key-value table, key being item name and value being a table:
			* `have` - how many the player has
			* `need` - how many of this item needed
		* `recipe` - the recipe
		* `craftable` - is craftable?
		* `displayed` - does is matchs the search (filter) ?      
	* `craftable` is a table of the items the player can craft with the items they have.
	* `uncraftable` is a table of items the player knows about, but is missing items for.

* crafting.get_all(type, level, item_hash, unlocked)
	* Returns same as above.
	* `item_hash` - a table with keys being item names or group names (eg: `group:wood`)
	                and the value being the number required.
	* `unlocked`  - a list of outputs the player has unlocked.

## Craft

* crafting.set_item_hashes_from_list(inv, listname, item_hash)
	* Iterates through the list and adds or updates entries in item_hash
	  representing the number of items for each names and group.

* crafting.find_required_items(inv, listname, recipe)
	* Returns a list of stacks to take, or nil if the required items could not
	  be found.

* crafting.has_required_items(inv, listname, recipe)
	* Returns true if the `"main"` list in `inv` contains the required items.

* crafting.perform_craft(name, inv, listname, outlistname, recipe)
	* Will try to take itemsfrom `listname` and put output in the `outlistname` list in `inv`.
	* Returns true on success.

* crafting.make_result_selector(player, type, level, size, context)
	* Generates a paginated form which a search box.
	* `type`    - craft type.
	* `size`    - how many slots to show on a page.
	* `context` - server-side storage between show and submit, can be `{}`.
		* `crafting_page` - page to show

* unused and commented in Exile --------------------------------------------
* crafting.result_select_on_receive_results(player, type, level, context, fields)
	* Handles form submissions for the result selector.
	* Returns true if the formspec should be shown again.

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
