
nodes_nature = nodes_nature
tgcr = tgcr

nodes_nature.replacement_types = {
   REPLACEMENT_WET = "wet", -- fresh water soaks in
   REPLACEMENT_DRY = "dry", -- water dries out
   REPLACEMENT_SALTY = "salty", -- salt water soaks in
   REPLACEMENT_SPREADING = "spreading:", -- group:spreading spreads here
   REPLACEMENT_BASE = "base", -- group:spreading dies out
   REPLACEMENT_AGRICULTURAL = "agricultural", -- result of tilling
   REPLACEMENT_DEPLETED = "depleted", -- deplete agricultural soil
   REPLACEMENT_ERODED = "eroded", -- erode agricultural soil
   REPLACEMENT_FERTILIZED = "fertilized", -- apply fertilizer to agricultural soil
}

local c = nodes_nature.replacement_types
-- use minetest.swap_node:
tgcr.configure_replacement(c.REPLACEMENT_WET, "keep_meta", true)
tgcr.configure_replacement(c.REPLACEMENT_DRY, "keep_meta", true)
tgcr.configure_replacement(c.REPLACEMENT_SALTY, "keep_meta", true)
