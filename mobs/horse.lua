----------------
-- Dead Horse --
----------------

local function horse_logic(self)
	
	if self.hp <= 0 then	
		mob_core.on_die(self)
		if mobkit.get_closest_entity(self, "grave:lich") then
			local lich = mobkit.get_closest_entity(self, "grave:lich")
			if lich:get_attach() then
				lich:set_detach()
				lich:set_properties({
					visual_size = {x = 1, y = 1}
				})
			end
		end
		return
	end

	local prty = mobkit.get_queue_priority(self)
	local pos = self.object:get_pos()
	local player = mobkit.get_nearby_player(self)

	if prty < 22 then
		if self.driver then
			mob_core.hq_mount_logic(self, 22)
			return
		end
	end

	if mobkit.timer(self,1) then 

		mob_core.vitals(self)
		mob_core.random_sound(self, 16)

		if prty < 22 then
            if self.mounted then
				grave.hq_mounted_logic(self, 22)
				return
            end
        end

		if prty < 20 and self.isinliquid then
			self.hp = 0
			return
		end

		if mobkit.is_queue_empty_high(self) then
			mob_core.hq_roam(self, 0, false)
		end
	end
end

minetest.register_entity("grave:dead_horse", {
    -- Stats
    max_hp = 30,
    armor_groups = {fleshy = 50},
    view_range = 32,
    reach = 3,
    damage = 6,
    knockback = 4,
    lung_capacity = 10,
    -- Movement & Physics
    max_speed = 6,
    stepheight = 1.1,
    jump_height = 2.26,
    max_fall = 3,
    buoyancy = 0,
    springiness=0,
    -- Visual
	collisionbox = {-0.55, -0.75, -0.55, 0.55, 0.8, 0.55},
	visual_size = {x = 15, y = 15},
	visual = "mesh",
	mesh = "grave_horse.b3d",
	textures = {"grave_dead_horse.png"},
	animation = {
		stand = {range = {x = 50, y = 100}, speed = 10, loop = true},
		walk = {range = {x = 1, y = 40}, speed = 30, loop = true},
		run = {range = {x = 1, y = 40}, speed = 45, loop = true},
	},
	-- Mount
	driver_scale = {x = 0.0665, y = 0.0665},
	driver_attach_at = {x = 0, y = 0.6, z = -0},
	driver_eye_offset = {{x = 0, y = 0.7, z = 0},{x = 0, y = 5, z = 7}},
	max_speed_forward = 12,
	max_speed_reverse = 6,
    -- Sound
    sounds = {
        random = {
            name = "grave_horse_idle",
            gain = 1.0,
            distance = 24
        },
        hurt = {
            name = "grave_horse_hurt",
            gain = 1.0,
            distance = 24
        },
        death = {
            name = "grave_horse_death",
            gain = 1.0,
            distance = 24
        }
    },
    -- Basic
    physical = true,
	collide_with_objects = true,
	static_save = true,
	timeout = 800,
	follow = {"bonemeal:bone"},
    logic = horse_logic,
    get_staticdata = mobkit.statfunc,
    on_step = mobkit.stepfunc,
	on_activate = mob_core.on_activate,
	on_rightclick = function(self, clicker)
		if mob_core.feed_tame(self, clicker, 12, false, false) then return end
		mob_core.protect(self, clicker, false)
		if clicker:get_wielded_item():get_name() == "mobs:saddle" then
            mob_core.mount(self, clicker)
        end
	end,
	on_punch = function(self, puncher, _, tool_capabilities, dir)
		mobkit.clear_queue_high(self)
		mob_core.on_punch_basic(self, puncher, tool_capabilities, dir)
        mob_core.on_punch_retaliate(self, puncher, false, true)
	end
})

mob_core.register_spawn_egg("grave:dead_horse", "4a2827", "393434")