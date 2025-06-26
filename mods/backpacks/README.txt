# Exile Mod: Backpacks
===============================================================================
Adds api for Backpacks bags which allow storage in the inventory.


`backpacks.register_backpack(name, desc, texture, size, groups, sounds)`
Will register a standard backpack with:
name, description, texture, inventory size, groups, sound

was changed to
backpacks.register_backpack(name, def)`
def being a table with following fields:
description - ex: S("Wicker Bag"),
texture - ex: "tech_wicker.png",
width - ex: 8,
height - ex:  2,
groups - ex: {snappy = 3, temp_pass = 1, craftedby = 1, flammable = 1},
sounds
_empty_name
_full_name
can_dump
can_pack
and more undocumented yet


Authors of source code
----------------------
Adapted for use in Exile from Backpacks by Everamzah (GNU GENERAL PUBLIC LICENSE)

Authors of media (textures)
---------------------------
Everamzah, unless otherwise stated.
