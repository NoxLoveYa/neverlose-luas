--initialize var
local properties = {
	ui_refs = {
		yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
		pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
		freestand = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding")
	},
	backup = {
		yaw = 0,
		pitch = 0
	},
	run = false,
	enable_on_freestanding = true
}
properties.backup.yaw = properties.ui_refs.yaw:get()
properties.backup.pitch = properties.ui_refs.pitch:get()

--initialize menu
local group = ui.create("Legit Anti-Aim")
local enable_on_freestanding = group:switch("Enable on freestanding", false)

--register menu events
enable_on_freestanding:set_callback(function(value)
	properties.enable_on_freestanding = value:get()
end, true)

--functions
local function is_defusing()
	local player = entity.get_local_player()
	if not player or not player:is_alive() then
		return false
	end
	local bomb = entity.get_entities("CPlantedC4")[1]
	if not bomb or bomb:get_origin():dist(player:get_origin()) > 40 then
		return false
	end
	return true
end

local function update_state(cmd)
	if cmd.in_use or (properties.enable_on_freestanding and properties.ui_refs.freestand:get()) then
		if not properties.run then
			properties.backup.yaw = properties.ui_refs.yaw:get()
			properties.backup.pitch = properties.ui_refs.pitch:get()
			properties.run = not is_defusing()
		elseif is_defusing() then
			properties.ui_refs.yaw:set(properties.backup.yaw)
			properties.ui_refs.pitch:set(properties.backup.pitch)
			properties.run = false
		end
	else
		if properties.run then
			properties.ui_refs.yaw:set(properties.backup.yaw)
			properties.ui_refs.pitch:set(properties.backup.pitch)
			properties.run = false
		end
	end
end

local function legit_aa(cmd)
	properties.ui_refs.yaw:set("Disabled")
	properties.ui_refs.pitch:set("Disabled")
end

--register events
events.createmove:set(function(cmd)
	update_state(cmd)
	if properties.run then
		cmd.in_use = false
		legit_aa(cmd)
	end
end)