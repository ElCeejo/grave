-------------
---- API ----
-------------
-- Ver 0.2 --

------------
-- Locals --
------------

local abs = math.abs

local function get_distance(self, obj)
	local pos = mobkit.get_stand_pos(self)
	local distance = vector.distance(pos, obj:get_pos())
	return distance
end

function grave.random_id()
    local idst = ""
    for _ = 0, 5 do idst = idst .. (math.random(0, 9)) end
    return idst
end


-----------------------
-- Movement Function --
-----------------------

function grave.goto_next_waypoint(self, tpos)
    local _, pos2 = mob_core.get_next_waypoint(self, tpos)
    grave.find_path(self, tpos)
    if self.path_data and #self.path_data > 2 then
        pos2 = self.path_data[3]
    end
    if pos2 then
		local yaw = self.object:get_yaw()
        local tyaw = minetest.dir_to_yaw(vector.direction(self.object:get_pos(),pos2))
        if abs(tyaw-yaw) > 0.1 then
            mobkit.turn2yaw(self, tyaw)
        end
        mobkit.lq_dumbwalk(self, pos2, 1)
		return true
    end
end

---------------------
-- HQ/LQ Functions --
---------------------

function grave.hq_summon(self, prty, look_at) -- Raise 6 Skeeltons
    local tyaw = 0
    local spawn_at = {}
    local init = false
    local spawn_timer = 4
    local spawned_skeletons = 0
    local stare_timer = 8
    local func = function(self)
        if not mobkit.is_alive(look_at) then
            mobkit.clear_queue_high(self)
            return true
        end
        if not init then
            mobkit.animate(self, "rise")
        end
        local pos = mobkit.get_stand_pos(self)
        local tpos = mobkit.get_stand_pos(look_at)
        local yaw = self.object:get_yaw()
        local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
        if math.abs(tyaw-yaw) > 0.1 then
            mobkit.turn2yaw(self, tyaw)
        end
        local area = minetest.find_nodes_in_area_under_air(
            vector.new(pos.x - 8, pos.y - 8, pos.z - 8),
            vector.new(pos.x + 8, pos.y + 8, pos.z + 8),
            grave.walkable_nodes
        )
        if #area < 6 then return end
        for i = 1, #area do
            if #spawn_at < 6 then
                table.insert(spawn_at, area[math.random(1, #area)])
                break
            end
        end

        for i = 1, #spawn_at do
            spawn_timer = spawn_timer - self.dtime
            if spawn_timer < 0 
            and spawned_skeletons < 6 then
                minetest.add_particlespawner({
                    amount = 32,
                    time = 4,
                    minpos = {x = spawn_at[i].x-0.5, y = spawn_at[i].y+0.5, z = spawn_at[i].z-0.5},
                    maxpos = {x = spawn_at[i].x+0.5, y = spawn_at[i].y+1.5, z = spawn_at[i].z+0.5},
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
                local skeleton = minetest.add_entity(spawn_at[i], "grave:skeleton")
                local ent = skeleton:get_luaentity()
                ent.lich_id = mobkit.remember(ent, "lich_id", self.lich_id)
                mob_core.logic_attack_player(ent, 20, look_at)
                spawned_skeletons = spawned_skeletons + 1
            end
        end
        stare_timer = stare_timer - self.dtime
        if stare_timer <= 0 then
            self.summon_cooldown = mobkit.remember(self, "summon_cooldown", 15)
            return true
        end
    end
    mobkit.queue_high(self, func, prty)
end

function grave.hq_fire_scepter(self, prty, target) -- Fire a Scepter Orb at Target
    local tyaw = 0
    local init = false
    local timer = 4
    local anim = ""
    local init = true
    local func = function(self)
        if not mobkit.is_alive(target) then
            mobkit.clear_queue_high(self)
            return true
        end
        if init then
            if self.mounted then
                mobkit.animate(self, "ride")
                anim = "ride"
            else
                mobkit.animate(self, "stand")
                anim = "stand"
            end
            init = false
        end
        local pos = mobkit.get_stand_pos(self)
        local tpos = mobkit.get_stand_pos(target)
        local yaw = self.object:get_yaw()
        local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))

        if vector.distance(pos, tpos) > 12 then
            grave.goto_next_waypoint(self, tpos)
        else
            if not self.mounted
            and math.abs(tyaw-yaw) > 0.1 then
                mobkit.turn2yaw(self, tyaw)
                mobkit.lq_idle(self, 1, "stand")
            end
            timer = timer - self.dtime
            if timer <= 0 then
                local cube = minetest.add_entity(pos, "grave:lich_cube")
                cube:get_luaentity().target = target
                timer = 4
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

function grave.hq_hunt(self, prty, target)
    local scan_pos = target:get_pos()
    scan_pos.y = scan_pos.y + 1
    local func = function(self)
        if not mobkit.is_alive(target) then
            mobkit.clear_queue_high(self)
            return true
        end
        local pos = mobkit.get_stand_pos(self)
        local tpos = target:get_pos()
        mob_core.punch_timer(self)
        if mobkit.is_queue_empty_low(self) then
            self.status = mobkit.remember(self, "status", "hunting")
            local dist = vector.distance(pos, tpos)
            local yaw = self.object:get_yaw()
            local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
            if abs(tyaw - yaw) > 0.1 then
                mobkit.lq_turn2pos(self, tpos)
            end
            if dist > self.view_range then
                self.status = mobkit.remember(self, "status", "")
                return true
            end
            local target_side = abs(target:get_properties().collisionbox[4])
            grave.goto_next_waypoint(self, tpos)
            if vector.distance(pos, tpos) < self.reach + target_side then
                self.status = mobkit.remember(self, "status", "")
                mob_core.lq_dumb_punch(self, target, "stand")
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

-----------
-- Logic --
-----------

function grave.lich_attack_player(self, prty, player) -- Attack player
    player = player or mobkit.get_nearby_player(self)
    if player
    and player:get_pos()
    and vector.distance(self.object:get_pos(), player:get_pos()) < self.view_range
    and mobkit.is_alive(player) then
        grave.hq_fire_scepter(self, prty, player)
        return
    end
    return
end

function grave.lich_attack_mob(self, prty) -- Attack specified mobs
    if self.targets then
        for i = 1, #self.targets do
            local target = mobkit.get_closest_entity(self, self.targets[i])
            if target
            and target:get_pos()
            and vector.distance(self.object:get_pos(), target:get_pos()) < self.view_range
            and mobkit.is_alive(target) then
                grave.hq_fire_scepter(self, prty, target)
                return
            end
        end
    end
end

function grave.logic_attack_player(self, prty, player) -- Attack player
    player = player or mobkit.get_nearby_player(self)
    if player
    and player:get_pos()
    and vector.distance(self.object:get_pos(), player:get_pos()) < self.view_range
    and mobkit.is_alive(player) then
        grave.hq_hunt(self,prty,player)
        return
    end
    return
end

function grave.logic_attack_mobs(self, prty, tbl) -- Attack specified mobs
    tbl = tbl or self.targets
    if tbl then
        for i = 1, #tbl do
            local target = mobkit.get_closest_entity(self, tbl[i])
            if target
            and target:get_pos()
            and vector.distance(self.object:get_pos(), target:get_pos()) < self.view_range
            and mobkit.is_alive(target) then
                if (self.tamed == true and target:get_luaentity().owner ~= self.owner)
                or not self.tamed then
                    grave.hq_hunt(self,prty,target)
                    return
                end
            end
        end
    end
end