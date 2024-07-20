--initialize var
local ui_refs = {
	["yaw"] = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
	["pitch"] = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
}
local backup = {
	["yaw"] = ui_refs.yaw:get(),
	["pitch"] = ui_refs.pitch:get(),
}
local running = 0

--functions
local function legit_aa(cmd)
	ui_refs.yaw:set("Disabled")
	ui_refs.pitch:set("Disabled")
end

--register events
events.createmove:set(function(cmd)
	if cmd.in_use then
		if running == 0 then
			backup.yaw = ui_refs.yaw:get()
			backup.pitch = ui_refs.pitch:get()
			running = 1
		end
	else
		if running == 1 then
			ui_refs.yaw:set(backup.yaw)
			ui_refs.pitch:set(backup.pitch)
			running = 0
		end

	end
	
	if running == 1 then
		cmd.in_use = false
		legit_aa(cmd)
	end
end)