-- FIXME: When `hud_scaling` is changed, the hotbar slot number-label HUD text
--  element positions, for some reason, do not get scaled exactly together with
--  the HUD image for *some* `hud_scaling` values, then they realign again.
--  The way they differ for various (noted) `hud_scaling` values can be
--  observed in the following pull-request comment:
--  https://codeberg.org/Mantar/Exile/pulls/495#issuecomment-1105503

local m_hud_data = {} -- minimal hud data store
local hud_type = minimal.hud_type

-- table of player hotbar slotnum hud elem ID stores
m_hud_data.hotbar_slotnums = {}

-- FIXME: The values below were determined experimentally and should instead be
--  get programmatically from a relevant MineTest API (from the subsystem that
--  sets up and/or draws the hotbar img & slots)!
-- CONST in Minetest v5.7.0 (invariant w.r.t. chosen hotbar img)
-- {
-- hotbar images get auto-scaled to match this height vertically (at `hud_scaling==1`)
local hotbar_height = 60
-- hotbar slot (pixel-)"boundary" size: side-length of slots inner area;
--  defines which pixels belong to the inside of the slot;
--  for a "symmetrical" slot border, the bounds are the border's middle-line
-- NOTE: Based on this definition neighbouring slots touch each other,
--  and their borders at the touching edge cover/overlay each other.
--  This is to make the position calc simpler than if we had to account for
--  spaces/borders *separating* slots (as slot position is not dependent on the
--  hotbar img).
local hotbar_slot_size = 56
-- offset of hotbar slot (pixel-)"boundary" bottom from bottom of hotbar img
local hotbar_slot_bottom_offset_y = -2
-- offset of hotbar image bottom from screen bottom edge (req: position.y == 1)
local hotbar_img_bottom_offset_y = -2
-- }

-- properties of used hotbar image
-- IF YOU CHANGE THE HOTBAR IMG, AJDUST THESE ACCORDINGLY!
-- {
-- if the slot borders are "symmetrical" (in vs. out of slot "boundary"),
--  the inner width is the half of the full border width
--  e.g. 2 for a 4px border on a "well-behaved" hotbar image
--  ("well-behaved": which is not distorted by MT hotbar img auto-scaling,
--   i.e., in MT v5.7.0, either a `(4+slotcount*56) x 60 px` image or one that
--   can be scaled to this size without distortion or loss of information)
local hotbar_slot_borderw_inner_top = 2
local hotbar_slot_borderw_inner_left = 2
-- }

-- use to CUSTOMIZE the looks of the hotbar slot number-labels
-- {
-- slot number text color
-- choose a color value to make the slot number very visible and differentiable
--  from the other numbers around the object in the hotbar slot
local hotbar_slotnum_color = "FFFFFF"
-- text elems left edge offset from slot left border's inner edge (req: alignment.x == 1)
local hotbar_slotnum_offset_x = 0
-- text elems top edge offset from slot top border's inner edge (req: alignment.y == 1)
local hotbar_slotnum_offset_y = 0
-- use monospace (true) or normal variable-width (false) font
local hotbar_slotnum_font_mono = false
-- }


minimal.update_hotbar_slotnums = function(player, hotbar_itemcount)
  local func_name = "minimal.update_hotbar_slotnums"
  -- check args
  -- {
  if not minetest.is_player(player) then
    local val_enclosure = type(player) == "string" and "\"" or ""
    minetest.log("error", func_name .. "():"
      .. " arg1 (`player`) must be a valid player object!"
      .. " Instead is type " .. type(player) .. " of value: "
      .. val_enclosure .. tostring(player) .. val_enclosure
    )
    return
  end

  if type(hotbar_itemcount) ~= "number" then
    local val_enclosure = type(hotbar_itemcount) == "string" and "\"" or ""
    minetest.log("error", func_name .. "():"
      .. " arg2 (`hotbar_itemcount`) must be a number!"
      .. " Instead is type " .. type(hotbar_itemcount) .. " of value: "
      .. val_enclosure .. tostring(hotbar_itemcount) .. val_enclosure
    )
    return
  end

  -- "round half up" (round up from <integer_part>.5)
  local hotbar_itemcount_int = math.floor(hotbar_itemcount + .5)
  if hotbar_itemcount ~= hotbar_itemcount_int then
    minetest.log("warning", func_name .. "():"
      .. " arg2 (`hotbar_itemcount`, orig.val.: " .. tostring(hotbar_itemcount)
      .. ") rounded to the nearest integer: " .. tostring(hotbar_itemcount_int)
    )
    hotbar_itemcount = hotbar_itemcount_int
  end

  local hotbar_itemcount_clamped = minimal.math_clamp(hotbar_itemcount, 1, 32)
  if hotbar_itemcount ~= hotbar_itemcount_clamped then
    minetest.log("warning", func_name .. "():"
      .. " arg2 (`hotbar_itemcount`, prev.val.: " .. tostring(hotbar_itemcount)
      .. ") clamped to the interval valid for hotbar itemcount (1..32): "
      .. tostring(hotbar_itemcount_clamped)
    )
    hotbar_itemcount = hotbar_itemcount_clamped
  end
  -- }

  -- number-label only slots which have keyboard shortcuts
  local hotbar_slotnum_last_idx = math.min(hotbar_itemcount, 10)

  -- get hotbar slotnum hud elem ID store for the given player,
  --  or create it if does not exist
  local player_hotbar_slotnums = m_hud_data.hotbar_slotnums[player:get_player_name()]
  if type(player_hotbar_slotnums) ~= "table" then
    player_hotbar_slotnums = {}
    m_hud_data.hotbar_slotnums[player:get_player_name()] = player_hotbar_slotnums
  end
  -- slotnums.count & slotnum_last_idx correspond, because slots are numbered from 1
  if player_hotbar_slotnums.count == hotbar_slotnum_last_idx then
    -- don't refresh the hud if the same number of hotbar_slotsnums is wanted
    return
  end
  player_hotbar_slotnums.count = hotbar_slotnum_last_idx

  -- remove old hud elems
  for key, hudid in pairs(player_hotbar_slotnums) do
    -- key of text elems is the index number of the corresponding hotbar slot
    --  so this should ignore "letter-named" keys such as "count"
    if type(key) == "number" then
      player:hud_remove(hudid)
    end
  end

  -- relative y (offset) coord of hotbar slot numbers to be created
  local hotbar_slotnum_y_rel  = (
    -- components hierarchically:
    0  -- at: screen bottom edge (req: position.y == 1)
    -- seems fixed in Minetest v5.7.0
    -- {
    +hotbar_img_bottom_offset_y  -- at: hotbar img bottom y (offset from screen bottom edge)
    -- at: slot "boundary" bottom edge inside hotbar img (offset from hotbar bottom edge)
    +hotbar_slot_bottom_offset_y
    -hotbar_slot_size  -- at: slot "boundary" top edge inside hotbar img
    -- }
    -- depends on chosen hotbar img
    -- at: slot top border's bottom edge inside hotbar slot
    +hotbar_slot_borderw_inner_top
    -- customize
    -- offset text elems top edge from slot top border's inner edge (req: alignment.y == 1)
    +hotbar_slotnum_offset_y
  )
  -- should be a tiny bit faster if not reallocating variables in each loop cycle
  local hotbar_slot_shift
  local hotbar_slotnum_x_rel
  for hotbar_slot_idx = 1, hotbar_slotnum_last_idx, 1 do
    -- curr. slot position in center-h.aligned hotbar (in units of "slot")
    hotbar_slot_shift = hotbar_slot_idx - 1 - hotbar_itemcount/2

    -- relative x (offset) coord of hotbar slot number to be created
    hotbar_slotnum_x_rel = (
      -- components hierarchically:
      0  -- at: horiz. center of screen (req: position.x == .5)
      -- `hotbar_slot_size` seems fixed in Minetest v5.7.0
      +hotbar_slot_shift * hotbar_slot_size  -- at: curr. slot "boundary"'s left edge
      -- depends on chosen hotbar img
      +hotbar_slot_borderw_inner_left  -- at: curr. slot left border's inner edge
      -- customize
      -- offset text elems left edge from slot left border's inner edge (req: alignment.x == 1)
      +hotbar_slotnum_offset_x
    )

    -- create hotbar slot number hud element & save its ID
    -- key of text elem is the index number of the hotbar slot
    player_hotbar_slotnums[hotbar_slot_idx] = player:hud_add({
      [hud_type] = "text",
      alignment = {x = 1, y = 1},  -- elem is to -1:left/up, 0:center, 1:right/down from anchor point
      -- elem is offset & anchored from point at 100% of screen y (bottom) & 50% of screen x (center)
      position = {x = .5, y = 1},
      offset = {x = hotbar_slotnum_x_rel, y = hotbar_slotnum_y_rel},
      number = tonumber("0x" .. hotbar_slotnum_color),  -- make it very visible
      text = tostring(hotbar_slot_idx % 10),
      style = hotbar_slotnum_font_mono and 4 or 0,  -- bitfield; 4: monospaced
    })
  end
end
