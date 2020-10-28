--------------------
-- Visual Objects --
--------------------
------ Ver 0.2 -----


-- Lich Cube --

local cube_def = {
    armor_groups = {immortal = 1},
    physical = false,
    visual = "cube",
    visual_size = {x=.5,y=.5,z=.5},
    textures = {
        "grave_lich_cube.png",
        "grave_lich_cube.png",
        "grave_lich_cube.png",
        "grave_lich_cube.png",
        "grave_lich_cube.png",
        "grave_lich_cube.png"
    },
    collisionbox = {0, 0, 0, 0, 0, 0},
    shooter = "",
    target = {},
    timer = 0.5,
    timeout = 10,
    on_step = function(self, dtime)
        self.object:set_armor_groups({immortal = 1})
        if self.target == {}
        or not mobkit.exists(self.target) then
            self.object:remove()
            return
        end
        local pos = self.object:get_pos()
        local tpos = self.target:get_pos()
        local dir = vector.direction(pos, tpos)
        self.object:set_velocity(vector.multiply(dir, 6))
        if self.timer > 0 then
            self.timer = self.timer - dtime
        else
            self.timer = 0.5
            minetest.add_particle({
                pos = pos,
                velocity = 0,
                acceleration = {x=0, y=0.2, z=0},
                expirationtime = 1,
                size = 4,
                collisiondetection = false,
                vertical = false,
                texture = "grave_lich_particle.png"
            })
            self.timeout = self.timeout - 1
        end
        if self.timeout <= 0 then
            self.object:remove()
        end
        if vector.distance(pos, tpos) < 2 then
            if self.target:get_luaentity()
            and self.target:get_luaentity().name:find("horse")
            and self.target:get_luaentity().name ~= "grave:dead_horse" then
                minetest.add_particlespawner({
                    amount = 32,
                    time = 4,
                    minpos = {x = tpos.x-0.5, y = tpos.y+0.5, z = tpos.z-0.5},
                    maxpos = {x = tpos.x+0.5, y = tpos.y+1.5, z = tpos.z+0.5},
                    minvel = {x = 0.5, y = 0.5, z = 0.5},
                    maxvel = {x = -0.5, y = 0.25, z = -0.5},
                    minacc = {x=0, y=0, z=0},
                    maxacc = {x=0, y=0, z=0},
                    minexptime = 0.5,
                    maxexptime = 1,
                    minsize = 2,
                    maxsize = 4,
                    collisiondetection = false,
                    vertical = false,
                    texture = "grave_lich_particle.png"
                })
                local horse = minetest.add_entity(tpos, "grave:dead_horse")
                if self.shooter then
                    mob_core.set_owner(horse:get_luaentity(), name)
                end
                self.target:remove()
                self.object:remove()
                return
            end
            self.target:punch(self.object, 2.0, {full_punch_interval = 0.1, damage_groups = {fleshy = 5}}, nil)
            if self.target:is_player() and self.target:get_hp() <= 0 then
                local lich = minetest.add_entity(tpos, "grave:lich")
                lich:get_luaentity().nametag = mobkit.remember(lich:get_luaentity(), "nametag", self.target:get_player_name())
            end
            self.object:remove()
        end
    end
}

minetest.register_entity("grave:lich_cube", cube_def)

-- Lich's Scepter Wield Visual --

local scepter_def = {
    armor_groups = {immortal = 1},
    physical = false,
    visual = "wielditem",
    visual_size = {x=.03,y=.03,z=.03},
    textures = {"grave:lich_scepter"},
    collisionbox = {0, 0, 0, 0, 0, 0},
    parent = "",
    on_step = function(self)
        self.object:set_armor_groups({immortal = 1})
        if not self.object:get_attach() then
            self.object:remove()
        end
    end
}

minetest.register_entity("grave:lich_scepter_ent", scepter_def)

-- Lich Eye Visual --

local eye_def = {
    armor_groups = {immortal = 1},
    physical = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    visual = "mesh",
    mesh = "grave_lich_eyes.b3d",
    visual_size = {x = 0.1, y = 0.1},
    textures = {"grave_lich_eyes.png"},
    is_visible = true,
    makes_footstep_sound = false,
    glow = 11,
    on_step = function(self)
        if not self.object:get_attach() then self.object:remove() end
    end
}

minetest.register_entity("grave:lich_eyes", eye_def)

-- Skeleton Sword Wield Visuals --

local stone_def = {
    armor_groups = {immortal = 1},
    physical = false,
    visual = "wielditem",
    visual_size = {x=.03,y=.03,z=.03},
    textures = {"default:sword_stone"},
    collisionbox = {0, 0, 0, 0, 0, 0},
    parent = "",
    on_step = function(self)
        self.object:set_armor_groups({immortal = 1})
        if not self.object:get_attach() then
            self.object:remove()
        end
    end
}

minetest.register_entity("grave:sword_stone", stone_def)

local steel_def = {
    armor_groups = {immortal = 1},
    physical = false,
    visual = "wielditem",
    visual_size = {x=.03,y=.03,z=.03},
    textures = {"default:sword_steel"},
    collisionbox = {0, 0, 0, 0, 0, 0},
    parent = "",
    on_step = function(self)
        self.object:set_armor_groups({immortal = 1})
        if not self.object:get_attach() then
            self.object:remove()
        end
    end
}

minetest.register_entity("grave:sword_steel", steel_def)