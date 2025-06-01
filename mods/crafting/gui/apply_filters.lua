local crafting = crafting

-- apply filters : search bar + panel filter if activated
local function apply_filters_to_list(cache, r_list)
    -- automatic filter in input field
    local i_filter = nil
    if cache.input_filter then
        local function get_stringtable(list)
            local s = {}
            local l = cache.pInv:get_list(list)
            for _,item in ipairs(l) do
                if not item:is_empty() then
                    s[#s+1] = item:get_name()
                end
            end
            -- return the table or nil if empty
            if next(s) then return s else return nil end
        end
        -- input field
        i_filter = get_stringtable("input_items")
    end

    for _, r in ipairs(r_list) do
        r.displayed = true
        --[[ each filter combines with previous filter,
        changing only already displayed recipes.
        If we want to make them reapper,
        we need to reset the display before calling current function]]
        -- apply input panel's filter
        if r.displayed then
            r.displayed = crafting.get_search_result(r, i_filter, cache.lang, true)
        end
        -- apply search field's filter
        if r.displayed then
            r.displayed = crafting.get_search_result(r, cache.sSearch, cache.lang, false)
        end
    end
end

local function cache_apply_filters(cache, optional_list)
    if optional_list then
        apply_filters_to_list(cache, optional_list, cache.inv)
    else
        for _,rlist in ipairs({cache.c_recipes,
                               cache.p_recipes,
                               cache.u_recipes,
                               cache.recipes}) do
            if rlist then
                apply_filters_to_list(cache, rlist, cache.inv)
            end
        end
    end
    -- erases recipes panel formspec part
    cache.FS_recipes = nil
    -- reset scroll bar to top
    cache.sScroll = 0 -- reset scrollbar to top
    return cache
end

crafting.register_cache_function("apply_filters", cache_apply_filters)

-- change Search field and reset formspec accordingly
-- return true is any change, to trigger formspec redraw
crafting.register_cache_function("set_text_search_to",
    function(self, s)
    local transformed = minimal.make_search_string(s)
    -- if I changed the text in the search field, reset recipes
    if self.sSearch ~= transformed then
        -- update cache with new search text
        self.sSearch = transformed
        -- erase txt field in formspec
        self.FS_search = nil
        -- updates recipes
        cache_apply_filters(self)
        -- tell I did something
        return true
    else
        return false
    end
end)
