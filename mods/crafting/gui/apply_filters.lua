local crafting = crafting



-- get a table of item names from an inv list
local function get_stringtable(inv, lists)
    local s = {}
    for _,list in pairs(lists) do
        local l = inv:get_list(list)
        for _,item in ipairs(l) do
            if not item:is_empty() then
                s[#s+1] = item:get_name()
            end
        end
    end
    -- return the table or nil if empty
    if next(s) then
        return s
    else
        return nil
    end
end

-- filter recipes, displaying only the one using items in input list
-- we can use "total" item using criteria parameter.
-- NOTE: we could add old check on recipes description to also test the output
local function filter_per_input_list(cache, pr, criteria)
    criteria = criteria or "craftable"
    -- if recipe is not tested yet, test it:
    if pr[criteria .. "_partial"] == nil then
        pr:update_state(cache:get_input_hash(criteria), criteria)
    end
    if pr[criteria .. "_partial"] then
        pr.displayed = true
    else
        pr.displayed = false
    end
    return pr.displayed
end

--[[ old version
-- `pr` is a player recipe
local function filter_per_input_list_as_string(cache, pr, criteria)
    -- using input items
    local item_list = cache:get_craft_input(criteria)
    local i_filter = get_stringtable(cache.pInv, item_list)
    return crafting.get_search_result(pr, i_filter, cache.lang, true)
end
]]--

-- apply filters : search bar + panel filter if activated
local function apply_filters_to_list(cache, r_list)
    local it_changed = false
    local old_value
    for _, r in ipairs(r_list) do
        old_value = r.displayed
        r.displayed = true
        --[[ each filter combines with previous filter,
        changing only already displayed recipes.
        If we want to make them reapper,
        we need to reset the display before calling current function]]

        -- apply input panel's filter except for "Use only"
        -- currently using nil as criteria (= "input" panel)
        if r.displayed and cache.input_filter and cache.craft_input ~=2 then
            -- r.displayed = filter_per_input_list_as_string(cache, r)
            filter_per_input_list(cache, r)
        end
        -- apply search field's filter
        if r.displayed then
            r.displayed = crafting.get_search_result(r, cache.sSearch, cache.lang, false)
        end
        if old_value ~= r.displayed then
            it_changed = true
        end
    end
    return it_changed
end

-- Apply filters to given recipe list and updated recipe panel.
-- An actual update of the recipe panel is suppressed unless it would actually
-- change or force_update is true.
local function cache_apply_filters(cache, optional_list, force_update)
    if not optional_list then
        optional_list = cache.recipes
    end

    local it_changed = apply_filters_to_list(cache, optional_list)

    if it_changed or force_update then
        -- erases recipes panel formspec part
        cache.FS_recipes = nil
        -- reset scroll bar to top
        cache.sScroll = 0 -- reset scrollbar to top
        return cache
    else
        return false -- no change, don't update formspec
    end
end

crafting.register_cache_function("apply_filters", cache_apply_filters)

-- change Search field and reset formspec accordingly
-- return true is any change, to trigger formspec redraw
crafting.register_cache_function("set_text_search_to", function(self, s)
    local transformed = minimal.make_search_string(s)
    -- if I changed the text in the search field, reset recipes
    if self.sSearch ~= transformed then
        -- update cache with new search text
        self.sSearch = transformed
        -- erase txt field in formspec
        self.FS_search = nil
        -- updates recipes
        if cache_apply_filters(self) then
            -- tell I did something
            return true
        end
    end
    -- else
    return false
end)
