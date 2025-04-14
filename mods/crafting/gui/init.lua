-- Crafting Mod - semi-realistic crafting in minetest
-- Copyright (C) 2018 rubenwardy <rw@rubenwardy.com>
-- Copyright (C) 2022 Jan Wielkiewicz <tona_kosmicznego_smiecia@interia.pl>
--
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- This library is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA


-- This mod adds a "exile_crafting" key to node definitions.

-- exile_crafting = {
-- name of craft type, or table of craft types.
--  A table produces tabs of recipes.
--      -- Must be registered with crafting.register_type().
--      craft_types = {'hand','hand_mixing'}
--      -- craft_types = 'craft_spot'           -- for single tab
--      craft_level = 1                         -- crafting level of node/item
--              }

--   * Items that have this key will auto transfer to the craft_type
--          inventory if moved into the input_items inventory.
--

local crafting_path = core.get_modpath("crafting")
dofile(crafting_path .. "/gui/crafting_formspec.lua")
dofile(crafting_path .. "/gui/apply_filters.lua")
dofile(crafting_path .. "/gui/recipes_panel.lua")
dofile(crafting_path .. "/gui/tools_and_types.lua")
