
tgcr = {}
-- this mod object
local tgcr = tgcr

local function ensure_sub_table(var, key, prototype)
    if type(var[key]) ~= "table" then
        var[key] = prototype or {} -- no table.copy to enable shared protos
    end
    return var[key]
end

-- resolve optional_depends on naturalslopeslib
local naturalslopeslib = _G.naturalslopeslib or {
    get_all_shapes = function(name) return { name } end,
                                                }

-- Replacement kind specifies the replacement set. A colon anywhere in
-- the replacement kind name specifies, that the replacement is hierarchical
-- (i.e. the name of the source node is important for selecting the replacement)
--
-- for currently used replacement see mods/nodes_nature/replacement_types.lua
--
-- parameter activation_source_name is used for hierarchical replacement only
--
-- example:
--   register_replacement("mod1:dirt_wet", "mod1.dirt_grassy_wet", "spreading:", "mod1:dirt_grassy_dry")
--   -- cause "dirt_wet be" replaced with "dirt_grassy_wet" when triggered by "dirt_grassy_dry" that is "spreading:"
-- register_replacement :: SourceNodeName -> TargetNodeName -> ReplacementKind -> Maybe[TriggerNodeName] -> Map[SourceNodeNameWithSlopeShape, TargetNodeNameWithSlopeShape]
function tgcr.register_replacement(source_node_name, target_node_name,
                                   replacement_kind, activation_source_name)
    activation_source_name = activation_source_name
        or target_node_name -- provide default

    local source_slopes = naturalslopeslib.get_all_shapes(source_node_name)
    local target_slopes = naturalslopeslib.get_all_shapes(target_node_name)
    local activation_slopes = naturalslopeslib.get_all_shapes(
        activation_source_name)

    local replacements = ensure_sub_table(tgcr,"replacements")
    local save_to_table = ensure_sub_table(replacements, replacement_kind)

    local prototype = {}
    if replacement_kind:find(":") then
        local next_table
        for _, tgt in ipairs(activation_slopes) do
            next_table = ensure_sub_table(save_to_table, tgt, prototype)
        end
        save_to_table = next_table
    end

    for i, src in ipairs(source_slopes) do
        local tgt = target_slopes[i] or target_slopes[1]
        save_to_table[src] = tgt
    end
    return save_to_table
end

-- find_replacement :: NodeName -> ReplacementKind -> NodeName -> NodeName
-- Return new node name to replace source_node_name with replacement_kind activated by activation_source_name.
function tgcr.find_replacement(source_node_name, replacement_kind,
                               activation_source_name)
    local a = tgcr.replacements or {}
    a = a[replacement_kind] or {}
    if replacement_kind:find(":") then
        a = a[activation_source_name] or {}
        return a[source_node_name] or source_node_name
    else
        return a[source_node_name] or source_node_name
    end
end

function tgcr.configure_replacement(replacement_kind, key, value)
    local replacement_cfg = ensure_sub_table(tgcr,"replacement_cfg")
    ensure_sub_table(replacement_cfg,replacement_kind)[key] = value
end

local function get_replacement_cfg(replacement_kind, cfg_name)
    -- this avoids using ensure_sub_table to let tgcr.replacement_cfg undefined
    local a = tgcr.replacement_cfg or {}
    a = a[replacement_kind] or {}
    return a[cfg_name]
end

-- make_replacement(pos, "spreading:", "mod1:dirt_grassy_dry")
function tgcr.make_replacement(pos, replacement_kind, activation_source_name)
    local source = minetest.get_node(pos)
    local target = {
        name = tgcr.find_replacement(source.name, replacement_kind,
                                     activation_source_name),
        param2 = source.param2
    }
    local node_setter = minetest.set_node
    if get_replacement_cfg(replacement_kind, "discard_param2") then
        target.param2 = nil
    end
    if get_replacement_cfg(replacement_kind, "keep_meta") then
        node_setter = minetest.swap_node
    end
    node_setter(pos, target)
end

function tgcr.get_replacible_list(replacement_kind, activation_source_name)
    local replacibles = ensure_sub_table(tgcr, "replacibles")
    local replacibles_known = ensure_sub_table(tgcr, "replacibles_known")
    local ix = replacement_kind
    if replacement_kind:find(":") then
        ix = replacement_kind .. "::" .. activation_source_name
    end
    if replacibles_known[ix] then
        return replacibles[ix]
    end
    replacibles_known[ix] = true
    replacibles[ix] = {}

    local replacements = ensure_sub_table(tgcr.replacements,replacement_kind)
    if replacement_kind:find(":") then
        replacements = ensure_sub_table(replacements,activation_source_name)
    end
    for src,_ in pairs(replacements) do
        table.insert(replacibles[ix], src)
    end
    return replacibles[ix]
end

--[[ --example replacement types
    ensure_sub_table(tgcr,"constants")
    tgcr.constants.REPLACEMENT_WET = "wet"
    tgcr.constants.REPLACEMENT_DRY = "dry"
    tgcr.constants.REPLACEMENT_SALTY = "salty"
    tgcr.constants.REPLACEMENT_SPREADING = "spreading:"
    tgcr.constants.REPLACEMENT_BASE = "base"
    tgcr.constants.REPLACEMENT_AGRICULTURAL = "agricultural"
--]]


local delayed_args = {}

-- Does the same thing as 'tgcr.register_replacement' but the
-- execution happens after all mods got loaded
function tgcr.delayed_register_replacement(source_node_name, target_node_name,
                                           replacement_kind, activation_source_name)
    table.insert(delayed_args, {
                     source_node_name,
                     target_node_name,
                     replacement_kind,
                     activation_source_name
    })
end

minetest.register_on_mods_loaded(function()
        for _, arg in ipairs(delayed_args) do
            tgcr.register_replacement(arg[1], arg[2], arg[3], arg[4])
        end
end)
