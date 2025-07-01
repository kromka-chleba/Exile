-- modifies how callbacks for items behave

minetest = minetest
core = core

-- Transfer metadata from node to item and back.
minetest.register_on_mods_loaded(function()
        -- Add a preserve_metadata callback to all nodes
        for oName, override in pairs( minetest.registered_nodes ) do
            local old_preserve_metadata = override.preserve_metadata
            minetest.override_item(
                oName, {
                    preserve_metadata = function(pos, oldnode, oldmeta, drops)
                        local imeta = drops[1] and drops[1]:get_meta()
                        -- if item meta, provide additional parameter: itemstack meta
                        if imeta then
                            minimal.metadata.preserve_metadata(imeta,oldmeta)
                            if type(old_preserve_metadata) == 'function' then
                                old_preserve_metadata(pos, oldnode,
                                                      oldmeta, drops, imeta)
                            end
                        end

                    end,
            })
            local old_after_place_node = override.after_place_node
            minetest.override_item(
                oName, {
                    after_place_node = function(pos, placer, itemstack,
                                                pointed_thing)
                        local imeta = itemstack:get_meta()
                        local meta = minetest.get_meta(pos)
                        minimal.metadata.after_place_node(imeta,meta)
                        -- provides additional parameters: nodemeta, itemstack meta
                        if type(old_after_place_node) == 'function' then
                            old_after_place_node(pos, placer, itemstack,
                                                 pointed_thing, meta, imeta)
                        end
                    end,
            })
        end

end)

-- add custom callbacks with engine registrations
core.register_on_liquid_transformed(function(pos_list, node_list)
    for index, pos in ipairs(pos_list) do
        local ndef, node = minimal.get_nodedef(pos)
        local onode = node_list[index] -- old node
        -- becoming or updating liquid (got liquid, meaning liquid flowed here or current liquid is flowing more or less)
        if ndef.drawtype == "liquid" or ndef.drawtype == "flowingliquid" then
            if ndef.on_liquid_transform then
                -- pos, oldnode, new node, new node's definition
                ndef.on_liquid_transform(pos, onode, node, ndef)
            end
        -- liquid pouring out or evaporating (got non-liquid)
        else
            local ndef = core.registered_nodes[onode.name]
            if ndef.drawtype == "liquid" or ndef.drawtype == "flowingliquid" then
                -- liquids can only become air (does not run for liquid getting replaced)
                if ndef.on_liquid_evaporate then
                    -- pos, oldnode, oldnode's def
                    ndef.on_liquid_evaporate(pos, onode, ndef)
                end
            end
        end
        -- ndef if statement ^
    end
end)