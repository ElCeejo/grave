--------------
-- Skeleton --
--------------

local target_list = {}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_entities) do
        if minetest.registered_entities[name].get_staticdata == mobkit.statfunc
        and not name:match("^grave:") then
			table.insert(target_list, name)
		end
	end
end)

local function add_sword(self, sword_type)
    local sword = minetest.add_entity(self.object:get_pos(), "grave:" .. sword_type)
    local ent = sword:get_luaentity()
    ent.parent = self.object
    sword:set_attach(self.object, "Bone.004", {x = 0.4, y = 0.6, z = 0.3}, {x = 90, y = -35, z = 50})
end

local function skeleton_logic(self)

    if self.hp <= 0 then
        mob_core.on_die(self)	
        return	
    end

    mob_core.collision_detection(self)

    local prty = mobkit.get_queue_priority(self)
    local pos = mobkit.get_stand_pos(self)
    local player = mobkit.get_nearby_player(self)

    if mobkit.timer(self, 1) then

        mob_core.vitals(self)
        mob_core.random_sound(self, 4)

        if prty < 4 then
            if player then
                grave.logic_attack_player(self, 4, player)
            end
        end

        if prty < 2 then
            grave.logic_attack_mobs(self, 2)
        end

        if mobkit.is_queue_empty_high(self) then
            mob_core.hq_roam(self, 0, true)
        end
    end
end

minetest.register_entity("grave:skeleton",{
    -- Stats
    max_hp = 20,
    armor_groups = {fleshy = 100},
    view_range = 32,
    reach = 2,
    damage = 3,
    knockback = 2,
    lung_capacity = 40,
    -- Movement & Physics
    max_speed = 3,
    stepheight = 1.1,
    jump_height = 1.1,
    max_fall = 6,
    buoyancy = 0,
    springiness = 0,
    -- Visual
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "grave_skeleton.b3d",
    textures = {"grave_skeleton.png"},
    animation = {
        stand = {range = {x = 1, y = 20}, speed = 15, loop = true},
        walk = {range = {x = 30, y = 50}, speed = 20, loop = true},
        run = {range = {x = 30, y = 50}, speed = 25, loop = true},
    },
    -- Sound
    sounds = {
        random = {
            name = "grave_skeleton_random",
            gain = 0.5,
            distance = 16
        },
        hurt = {
            name = "grave_skeleton_hurt",
            gain = 1.0,
            distance = 16
        },
        death = {
            name = "grave_skeleton_death",
            gain = 1.0,
            distance = 16
        }
    },
    -- Basic
    physical = true,
    collide_with_objects = true,
    static_save = true,
    ignore_liquidflag = false,
    punch_cooldown = 1,
    targets = target_list,
    drops = {
        {name = "bonemeal:bone", chance = 1, min = 1, max = 3}
    },
    timeout = 0,
    logic = skeleton_logic,
    get_staticdata = mobkit.statfunc,
	on_activate = function(self, staticdata, dtime_s)
        mob_core.on_activate(self, staticdata, dtime_s)
        self.lich_id = mobkit.recall(self, "lich_id") or nil
        if not self.weapon then
            if math.random(1, 2) == 1 then
                self.weapon = mobkit.remember(self, "weapon", "sword_stone")
                add_sword(self, self.weapon)
            else
                self.weapon = mobkit.remember(self, "weapon", "sword_steel")
                add_sword(self, self.weapon)
            end
        end
        self.weapon = mobkit.recall(self, "weapon")
        if self.weapon == "default:sword_stone" then
            self.damage = 4
        else
            self.damage = 6
        end
        add_sword(self, self.weapon)
	end,
    on_step = function(self, dtime)
        mobkit.stepfunc(self, dtime)
    end,
    on_punch = function(self, puncher, _, tool_capabilities, dir)
        mob_core.on_punch_basic(self, puncher, tool_capabilities, dir)
        mob_core.on_punch_retaliate(self, puncher, false, true)
        if puncher:get_wielded_item():get_name() == "draconis:draconic_steel_sword" then
            self.object:remove()
        end
    end
})


mob_core.register_spawn_egg("grave:skeleton", "bdbdbd", "797979")


minetest.register_chatcommand("graveyard", {
	params = "",
	description = "Test 1: Modify player's inventory view",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false
		end
		local pos = player:get_pos()
        local pos1 = vector.subtract(pos, 16)
        local pos2 = vector.add(pos, 16)
        local candidates = minetest.find_nodes_in_area_under_air(pos1, pos2, "grave:grave_dirt_with_grave_grass")
        local spawned_stones = {}
        if #candidates < 8 then minetest.chat_send_all("text") return end
        while #spawned_stones < 16 do
            local i = math.random(1, #candidates)
            local top = vector.new(candidates[i].x, candidates[i].y + 1, candidates[i].z)
            if minetest.get_node(top).name == "air" then
                table.insert(spawned_stones, top)
                minetest.set_node(top, {name = "default:stone"})
            end
        end
	end,
})