-------------
---- Lich ---
-------------

local function set_mob_tables(self)
    for _,entity in pairs(minetest.luaentities) do
        if mob_core.is_mobkit_mob(entity) then -- Check if mob is aquatic
            if entity.name:find("horse")
            and entity.name ~= "grave:dead_horse"
            and not draconis.find_value_in_table(self.targets, entity.name) then
                if entity.object:get_armor_groups() and entity.object:get_armor_groups().fleshy then
                    table.insert(self.targets, entity.name)
                elseif entity.name:match("^petz:") then -- petz doesn't use armor groups, so they have to checked seperately
                    table.insert(self.targets,entity.name)
                end
            end
        end
    end
end

local function eyes(self)
    local eyes = minetest.add_entity(self.object:get_pos(), "grave:lich_eyes")
    eyes:set_attach(self.object, "Bone.001", {x = 0, y = -1.214, z = -0.412}, {x = 0, y = 0, z = 0})
end

local function add_scepter(self)
    local sword = minetest.add_entity(self.object:get_pos(), "grave:lich_scepter_ent")
    local ent = sword:get_luaentity()
    ent.parent = self.object
    sword:set_attach(self.object, "Bone.004", {x = 0.4, y = 0.6, z = 0.3}, {x = 90, y = -35, z = 50})
end

local function mount_horse(self, horse)
    self.object:set_attach(horse, nil, {x = 0, y = 0.15, z = 0}, {x = 0, y = 0, z = 0})
    self.object:set_properties({
        visual_size = {x = 0.0665, y = 0.0665}
    })
end

local function spawn_mounted_horse(self)
    local pos = self.object:get_pos()
    local horse = minetest.add_entity(pos, "grave:dead_horse")
    mount_horse(self, horse)
end

local function lich_logic(self)
	
    if self.hp <= 0 then
        for _, ent in pairs(minetest.luaentities) do
            if ent.name
            and ent.name == "grave:skeleton"
            and ent.lich_id
            and ent.lich_id == self.lich_id then
                ent.hp = 0
            end
        end   
        mob_core.on_die(self)	
        return	
    end

    mob_core.collision_detection(self)

    local prty = mobkit.get_queue_priority(self)
    local pos = mobkit.get_stand_pos(self)
    local player = mobkit.get_nearby_player(self)

    if mobkit.timer(self, 1) then

        mob_core.vitals(self) -- Environmental Damage
        mob_core.random_sound(self) --  Random Sounds

        self.summon_cooldown = mobkit.remember(self, "summon_cooldown", self.summon_cooldown-self.dtime)

        if self.mounted then
            mobkit.animate(self, "ride")
            return
        end

        if prty < 4 then
            if self.mounted or self.summon_cooldown > 0 then
                if player then
                    grave.lich_attack_player(self, 4, player)
                else
                    grave.lich_attack_mob(self, prty) 
                end
            end
        end

        if prty < 2 then
            if player then
                if self.summon_cooldown <= 0 then
                    grave.hq_summon(self, 2, player)
                end
            end
        end

        if mobkit.is_queue_empty_high(self) then
            mob_core.hq_roam(self, 0, true)
        end
    end
end

minetest.register_entity("grave:lich",{
    -- Stats
    max_hp = 120,
    armor_groups = {fleshy = 50},
    view_range = 16,
    reach = 1,
    damage = 1,
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
    mesh = "grave_lich.b3d",
    textures = {"grave_lich.png"},
    animation = {
        stand = {range = {x = 1, y = 20}, speed = 15, loop = true},
        walk = {range = {x = 30, y = 50}, speed = 20, loop = true},
        run = {range = {x = 30, y = 50}, speed = 25, loop = true},
        rise = {range = {x = 60, y = 65}, speed = 5, loop = false},
        ride = {range = {x = 70, y = 80}, speed = 5, loop = false},
    },
    -- Sound
    sounds = {
        random = {
            name = "grave_lich_idle",
            gain = 1.0,
            distance = 16
        },
        hurt = {
            name = "grave_lich_hurt",
            gain = 1.0,
            distance = 16
        },
        death = {
            name = "grave_lich_death",
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
    drops = {
        {name = "bonemeal:bone", chance = 1, min = 1, max = 3},
        {name = "grave:lich_scepter", chance = 16, min = 1, max = 1}
    },
    timeout = 0,
    logic = lich_logic,
    get_staticdata = mobkit.statfunc,
	on_activate = function(self, staticdata, dtime_s)
        mob_core.on_activate(self, staticdata, dtime_s)
        self.lich_id = mobkit.recall(self, "lich_id") or 1
        if self.lich_id == 1 then
            self.lich_id =
                mobkit.remember(self, "lich_id", grave.random_id())
        end
        self.mounted = mobkit.recall(self, "mounted") or nil
        self.summon_cooldown = mobkit.recall(self, "summon_cooldown") or 0
        add_scepter(self)
        eyes(self)
        if not self.mounted then
            if math.random(1, 6) == 1 then
                self.mounted = mobkit.remember(self, "mounted", true)
                spawn_mounted_horse(self)
            else
                self.mounted = mobkit.remember(self, "mounted", false)
            end
        elseif self.mounted
        and not self.object:get_attach() then
            if mobkit.get_closest_entity(self, "grave:dead_horse") then
                mount_horse(self, mobkit.get_closest_entity(self, "grave:dead_horse"))
            else
                self.mounted = mobkit.remember(self, "mounted", false)
            end
        end
	end,
    on_step = function(self, dtime)
        mobkit.stepfunc(self, dtime)
        if self.mounted
        and not self.object:get_attach() then
            if mobkit.exists(self)
            and mobkit.get_closest_entity(self, "grave:dead_horse") then
                mount_horse(self, mobkit.get_closest_entity(self, "grave:dead_horse"))
            else
                self.object:set_properties({
					visual_size = {x = 1, y = 1}
				})
                self.mounted = mobkit.remember(self, "mounted", false)
            end
        end
    end,
    on_punch = function(self, puncher, _, tool_capabilities, dir)
        mob_core.on_punch_basic(self, puncher, tool_capabilities, dir)
        if puncher:get_wielded_item():get_name() == "draconis:sword_draconic_steel" then
            local pos = self.object:get_pos()
            minetest.add_particlespawner({
				amount = 6,
				time = 0.25,
				minpos = {x = pos.x - 7/16, y = pos.y - 5/16, z = pos.z - 7/16},
				maxpos = {x = pos.x + 7/16, y = pos.y - 5/16, z = pos.z + 7/16},
				minvel = vector.new(-1, 2, -1),
				maxvel = vector.new(1, 5, 1),
				minacc = vector.new(0, -9.81, 0),
				maxacc = vector.new(0, -9.81, 0),
				collisiondetection = true,
				texture = "default_ice.png",
			})
            self.object:remove()
        end
    end
})


mob_core.register_spawn_egg("grave:lich", "7e5acb", "3c1aa4")

mob_core.register_spawn({
	name = "grave:lich",
	nodes = {"grave:grave_dirt_with_grave_grass"},
	min_light = 0,
	max_light = 6,
	min_height = -31000,
	max_height = 31000,
	min_rad = 24,
	max_rad = 256,
	group = 6
}, 2, 8)