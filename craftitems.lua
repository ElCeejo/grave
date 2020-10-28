-----------------
-- Craft Items --
-----------------
---- Ver 0.2 ----

minetest.register_craftitem("grave:lich_scepter", {
    description = "Lich's Scepter",
    inventory_image = "grave_lich_scepter.png",
    wield_scale = {x = 2, y = 2, z = 1},
    stack_max = 1,
    on_use = function(itemstack, player)
        local ppos = player:get_pos()
        ppos.y = ppos.y + 1
        local pos1 = vector.add(ppos, vector.multiply(player:get_look_dir(), 1))
	    local pos2 = vector.add(pos1, vector.multiply(player:get_look_dir(), 24))
	    local ray = minetest.raycast(pos1, pos2, true, false)
        for pointed_thing in ray do
            if not pointed_thing then return end
            if pointed_thing.type == "object" then
                if pointed_thing.ref:get_armor_groups().fleshy then
                    local cube =  minetest.add_entity(pos1, "grave:lich_cube")
                    cube:get_luaentity().target = pointed_thing.ref
                    cube:get_luaentity().shooter = player:get_player_name()
                end
            end
        end
    end,
})