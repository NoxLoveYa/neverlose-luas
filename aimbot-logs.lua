--globals definition
local hitgroup_str = {
    [0] = 'generic',
    'head', 'chest', 'stomach',
    'left arm', 'right arm',
    'left leg', 'right leg',
    'neck', 'generic', 'gear'
}

local properties = {
	console = true,
	notification = false
}

--setup the menu
local group = ui.create("Aimbot logs")
local dropdown = group:selectable("Logs Render", {"Console", "Notification"})

--register menu events
dropdown:set_callback(function(value)
	properties.console = value:get("Console")
	properties.notification = value:get("Notification")
end, true)

--register events
events.aim_ack:set(function(log)
	
	if not log then return end
	
	local name = log.target:get_name()
	
	local w_damage = log.wanted_damage
	local damage = log.damage
	local damage_dif = 0
	
	local backtrack = log.backtrack
	
	local reason = log.state
	
	local health = log.target.m_iHealth
	local text = ""

	--build the log
	if damage then
		damage_dif = w_damage - damage

		if damage_dif ~= 0 then
			if reason then
				text = string.format("\aFF8000FF[Oasis.lua]\aFFFFFFFF \aFF675CFFMissMatched\aFFFFFFFF due to \aFFAA5AFF%s\aFFFFFFFF: \a7693FFFF%s\aFFFFFFFF for \aD0FF5CFF%d\aFFFFFFFF (\aFFA7AFFF%d\aFFFFFFFF wanted) in the \aFFF05CFF%s\aFFFFFFFF | bt ticks: \a5CFFD7FF%d\aFFFFFFFF | health remaining: \aD0FF5CFF%d\aFFFFFFFF", reason, name:lower(), damage, w_damage, hitgroup_str[log.hitgroup], backtrack, health)
			else
				text = string.format("\aFF8000FF[Oasis.lua]\aFFFFFFFF \aFF675CFFMissMatched\aFFFFFFFF for \aFFAA5AFFunknown\aFFFFFFFF reason: \a7693FFFF%s\aFFFFFFFF for (\aD0FF5CFF%d\aFFFFFFFF/\aFFA7AFFF%d\aFFFFFFFF) in the \aFFF05CFF%s\aFFFFFFFF | bt ticks: \a5CFFD7FF%d\aFFFFFFFF | health remaining: \aD0FF5CFF%d\aFFFFFFFF", name:lower(), damage, w_damage, hitgroup_str[log.hitgroup], backtrack, health)
			end
		else
			if reason then
				text = string.format("\aFF8000FF[Oasis.lua]\aFFFFFFFF \a5CB3FFFFShot\aFF675CFF/\aFFAA5AFF%s\aFFFFFFFF: \a7693FFFF%s\aFFFFFFFF for \aD0FF5CFF%d\aFFFFFFFF in the \aFFF05CFF%s\aFFFFFFFF | bt ticks: \a5CFFD7FF%d\aFFFFFFFF | health remaining: \aD0FF5CFF%d\aFFFFFFFF", reason, name:lower(), damage, hitgroup_str[log.hitgroup], backtrack, health)
			else
				text = string.format("\aFF8000FF[Oasis.lua]\aFFFFFFFF \a5CB3FFFFShot\aFF675CFF/\aABFF5CFFhit\aFFFFFFFF: \a7693FFFF%s\aFFFFFFFF for \aD0FF5CFF%d\aFFFFFFFF in the \aFFF05CFF%s\aFFFFFFFF | bt ticks: \a5CFFD7FF%d\aFFFFFFFF | health remaining: \aD0FF5CFF%d\aFFFFFFFF", name:lower(), damage, hitgroup_str[log.hitgroup], backtrack, health)
			end
		end
	else
		if reason then
			text = string.format("\aFF8000FF[Oasis.lua] \aFF675CFFMissed\aFFFFFFFF due to \aFFAA5AFF%s\aFFFFFFFF: \a7693FFFF%s\aFFFFFFFF for \aD0FF5CFF%d\aFFFFFFFF in the \aFFF05CFF%s\aFFFFFFFF | bt ticks: \a5CFFD7FF%d\aFFFFFFFF", reason, name:lower(), w_damage, hitgroup_str[log.wanted_hitgroup], backtrack)
		else
			text = string.format("\aFF8000FF[Oasis.lua] \aFF675CFFMissed\aFFFFFFFF for \aFFAA5AFFunknown\aFFFFFFFF reason: \a7693FFFF%s\aFFFFFFFF for \aD0FF5CFF%d\aFFFFFFFF in the \aFFF05CFF%s\aFFFFFFFF | bt ticks: \a5CFFD7FF%d\aFFFFFFFF", name:lower(), w_damage, hitgroup_str[log.wanted_hitgroup], backtrack)
		end
	end
	--print log to the console
	if properties.console then
		print_raw(text)
	end
	--print log to the notification
	if properties.notification then
		common.add_event(text, "wand-magic-sparkles")
	end
end)