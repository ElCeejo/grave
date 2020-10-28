--------------
--- Mapgen ---
--------------
--- Ver 0.2 --


-- Helper Functions --

local function get_biome_name(pos)
	if not pos then return end
	return minetest.get_biome_name(minetest.get_biome_data(pos).biome)
end

-- Mapgen --

minetest.register_biome({
	name = "grave",
	node_top = "grave:grave_dirt_with_grave_grass",
	depth_top = 1,
	node_filler = "grave:grave_dirt",
	depth_filler = 16,
	node_stone = "default:stone",
	y_min = l,
	y_max = 31000,
	heat_point = 20,
	humidity_point = 75
})


minetest.register_decoration({
	name = "grave:grave_oak_tree",
	deco_type = "schematic",
	place_on = {"grave:grave_dirt_with_grave_grass"},
	sidelen = 80,
	noise_params = {
		offset = 0.010,
		scale = -0.048,
		spread = {x = 50, y = 50, z = 50},
		seed = 2,
		octaves = 3,
		persist = 0.66
	},
	y_min = 1,
	y_max = 31000,
	schematic = minetest.get_modpath("grave") .. "/schems/grave_grave_oak.mts",
	flags = "place_center_x, place_center_z",
	rotation = "random"
})

-- Skybox --

local grave_sky = {}

local timer = 1

local function set_grave_sky(player)
    local func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end
        local biome = get_biome_name(player:get_pos())
        if biome == "grave" and not grave_sky[name] then
            grave_sky[player:get_player_name()] = true
            player:set_sky({r=64, g=56, b=64}, "plain", {}, false)
        end
        if biome ~= "grave" and grave_sky[player:get_player_name()] then
            player:set_sky(nil, "regular")
            grave_sky[player:get_player_name()] = false
        end
    end
    minetest.after(1, func, player:get_player_name())
end


minetest.register_globalstep(function(dtime)
    timer = timer - dtime
    for _,player in ipairs(minetest.get_connected_players()) do
        if timer < 0 then
            set_grave_sky(player)
        end
    end
end)