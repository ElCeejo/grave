grave = {}

local path = minetest.get_modpath("grave")

grave.walkable_nodes = {}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if minetest.registered_nodes[name].walkable then
				table.insert(grave.walkable_nodes, name)
			end
		end
	end
end)



dofile(path.."/api/api.lua")
dofile(path.."/api/pathfinding.lua")
dofile(path.."/mobs/visual_objects.lua")
dofile(path.."/mobs/horse.lua")
dofile(path.."/mobs/lich.lua")
dofile(path.."/mobs/skeleton.lua")
dofile(path.."/nodes.lua")
dofile(path.."/mapgen.lua")
dofile(path.."/craftitems.lua")