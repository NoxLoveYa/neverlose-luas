-- VAR
local DEBUG = true
local auto_tp_in_air_enabled = true
local tp_delay = 8
local tp_recharge_delay = 24
local tp_velocity_treshold = 0
local animation_speed = 5
local icon = ui.get_icon("wand-magic-sparkles")
local local_player = entity.get_local_player()
local current_velocity = vector(0, 0, 0)

-- COLOR VARS
local accent_color = color(255, 208, 208)
local other_color = color(225, 255)
local gradient_start = color(115, 75, 75, 190)
local gradient_end = color(255, 208, 208, 255)

-- BUFFERS
local old_weapon = nil
local current_threat = nil
local tp_temp = 0
local tp_recharge_temp = 0
local is_recharging = false
local scroll_offset = 0

-- UI
local doubletap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap")
local main_group = ui.create("StarTools.lua")

-- Debug Panel Toggle with color subgroup
local debug_panel_toggle = main_group:switch("Show Debug Panel", true)
local debug_panel_group = debug_panel_toggle:create("Debug Panel Settings")

-- Animation Speed Slider
local animation_speed_slider = debug_panel_group:slider("Animation Speed", -20, 20, -10)
animation_speed = animation_speed_slider:get()

animation_speed_slider:set_callback(function(ctx)
    animation_speed = ctx:get()
end)

-- Color Pickers with callbacks
local accent_color_picker = debug_panel_group:color_picker("Accent Color", accent_color)
local other_color_picker = debug_panel_group:color_picker("Other Color", other_color)
local gradient_start_picker = debug_panel_group:color_picker("Gradient Start", gradient_start)
local gradient_end_picker = debug_panel_group:color_picker("Gradient End", gradient_end)

-- Set initial values
accent_color = accent_color_picker:get()
other_color = other_color_picker:get()
gradient_start = gradient_start_picker:get()
gradient_end = gradient_end_picker:get()

-- Color picker callbacks
accent_color_picker:set_callback(function(ctx)
    accent_color = ctx:get()
end)

other_color_picker:set_callback(function(ctx)
    other_color = ctx:get()
end)

gradient_start_picker:set_callback(function(ctx)
    gradient_start = ctx:get()
end)

gradient_end_picker:set_callback(function(ctx)
    gradient_end = ctx:get()
end)

-- Auto TP Switch
local air_tp = main_group:switch("Auto TP In Air")
auto_tp_in_air_enabled = air_tp:get()

air_tp:set_callback(function(ctx)
    auto_tp_in_air_enabled = ctx:get()
end)

-- Auto TP Group
local air_tp_group = air_tp:create("Auto TP Settings")
local air_tp_delay_slider = air_tp_group:slider("TP Delay", 0, 64, 8)
local air_tp_recharge_slider = air_tp_group:slider("TP Recharge Delay", 0, 64, 24)
local air_tp_velocity_slider = air_tp_group:slider("TP Recharge Velocity Treshold", -350, 350, -45)

tp_delay = air_tp_delay_slider:get()
tp_recharge_delay = air_tp_recharge_slider:get()
tp_velocity_treshold = air_tp_velocity_slider:get()

air_tp_delay_slider:set_callback(function(ctx)
    tp_delay = ctx:get()
end)

air_tp_recharge_slider:set_callback(function(ctx)
    tp_recharge_delay = ctx:get()
end)

air_tp_velocity_slider:set_callback(function(ctx)
    tp_velocity_treshold = ctx:get()
end)

-- FUNCTIONS
local function round(num)
	return math.floor(num + 0.5)
end
	
local function get_gradient_text(text, start_color, end_color, offset)
    local result = {}
    local chars = {}

    -- Collect characters
    for char in text:gmatch(".") do
        table.insert(chars, char)
    end

    -- Count visible characters
    local visible_count = 0
    for _, char in ipairs(chars) do
        if char ~= " " then
            visible_count = visible_count + 1
        end
    end

    if visible_count == 0 then
        return text
    end

    -- Circular offset
    offset = offset % visible_count

    local char_index = 0
    for _, char in ipairs(chars) do
        if char == " " then
            table.insert(result, char)
        else
            local position = (char_index + offset) / visible_count
            position = position % 1  -- Wrap perfectly

            local t = (1 - math.cos(position * math.pi * 2)) * 0.5

            -- Interpolate colors
            local r = math.floor(start_color.r + (end_color.r - start_color.r) * t)
            local g = math.floor(start_color.g + (end_color.g - start_color.g) * t)
            local b = math.floor(start_color.b + (end_color.b - start_color.b) * t)
            local a = math.floor(start_color.a + (end_color.a - start_color.a) * t)

            -- Clamp values
            r = math.min(255, math.max(0, r))
            g = math.min(255, math.max(0, g))
            b = math.min(255, math.max(0, b))
            a = math.min(255, math.max(0, a))

            table.insert(result, string.format("\a%02X%02X%02X%02X%s", r, g, b, a, char))
            char_index = char_index + 1
        end
    end

    return table.concat(result)
end

local function autoTP(in_bhop)
    if not current_threat or not in_bhop then
        tp_temp = 0
        tp_recharge_temp = 0
        is_recharging = false
        return
    end

    -- Waiting to start recharge
    if tp_recharge_temp > 0 and not is_recharging then
        tp_recharge_temp = tp_recharge_temp + 1

        if tp_recharge_temp >= tp_recharge_delay then
            is_recharging = true
            tp_recharge_temp = 0
        else
            return
        end
    end

    -- Recharging mode
    if is_recharging then
        rage.exploit:force_charge()

        if rage.exploit:get() == 1 then
            is_recharging = false
        end
        return
    end

    -- Start charging if not charged
    if rage.exploit:get() ~= 1 then
        is_recharging = true
        return
    end

    -- Teleport logic when fully charged
    if rage.exploit:get() == 1 then
        tp_temp = tp_temp + 1
        if tp_temp >= tp_delay and in_bhop then
            local z_velocity = current_velocity.z
            local should_teleport = false
            
            if tp_velocity_treshold == 0 then
                -- Disabled - always teleport
                should_teleport = true
            elseif tp_velocity_treshold < 0 then
                -- Negative threshold: teleport when velocity is UNDER threshold (more negative)
                should_teleport = z_velocity <= tp_velocity_treshold
            else
                -- Positive threshold: teleport when velocity is OVER threshold (more positive)
                should_teleport = z_velocity >= tp_velocity_treshold
            end
            
            if should_teleport then
                tp_temp = 0
                rage.exploit:force_teleport()
                tp_recharge_temp = 1
            end
        end
    end
end

local function render_debug_panel(scroll_offset)
    local screen_size = render.screen_size()
    local panel_y_offset = -0
    local panel_pos = vector(5, screen_size.y / 2 + panel_y_offset)

    local watermark_text = "|-| StarTools |-|"
    local threat_text = "Current Threat: "
    local exploit_text = "TP Exploit: "
    local velocity_text = "Direction: "

    local rendered_texts = {
	 	velocity_text,
        exploit_text,
        threat_text,
        watermark_text
    }

    local max_y_size = 0
    for _, text in pairs(rendered_texts) do
        max_y_size = max_y_size + render.measure_text(4, "", text).y
    end

    local offset = -(max_y_size / 2)
	local gradient_inverted = true
    for _, text in pairs(rendered_texts) do
        local cur_color = (text == watermark_text) and accent_color or other_color

        if text == watermark_text then
            render.text(4, panel_pos - vector(0, offset), accent_color, nil, icon..get_gradient_text(text, gradient_inverted and gradient_end or gradient_start, gradient_inverted and gradient_start or gradient_end, scroll_offset))
        else
            render.text(4, panel_pos - vector(0, offset), cur_color, nil, text)
        end

        local text_size = render.measure_text(4, "", text)

        if text == threat_text then
            local threat_name = current_threat and "~" .. current_threat:get_name() .. "~" or "~Safe~"
            render.text(4, panel_pos - vector(-text_size.x, offset), accent_color, nil, get_gradient_text(threat_name, gradient_inverted and gradient_end or gradient_start, gradient_inverted and gradient_start or gradient_end, scroll_offset))
        elseif text == exploit_text then
            local status_text = "~Idle~"

            if not doubletap:get() then
                status_text = "~Doubletap disabled~"
            elseif not auto_tp_in_air_enabled then
                status_text = "~Disabled~"
            elseif current_threat then
                if tp_temp > 0 then
                    if tp_velocity_treshold ~= 0 then
                        status_text = "~Waiting (z:" .. tp_velocity_treshold .. ")~"
                    else
                        status_text = "~Active~"
                    end
                elseif is_recharging then
                    status_text = "~Recharging~"
                elseif tp_recharge_temp > 0 then
                    status_text = "~Waiting~"
                else
                    status_text = "~Idle~"
                end
            end

            render.text(4, panel_pos - vector(-text_size.x, offset), accent_color, nil, get_gradient_text(status_text, gradient_inverted and gradient_end or gradient_start, gradient_inverted and gradient_start or gradient_end, scroll_offset))
        elseif text == velocity_text then
			local abs_x = round(math.abs(current_velocity.x))
		    local abs_y = round(math.abs(current_velocity.y))
		    local abs_z = round(math.abs(current_velocity.z))
			local velocity_display = string.format("x:%s | y:%s | z:%s", abs_x, abs_y, abs_z)
    		render.text(4, panel_pos - vector(-text_size.x, offset), accent_color, nil, get_gradient_text(velocity_display, gradient_inverted and gradient_end or gradient_start, gradient_inverted and gradient_start or gradient_end, scroll_offset))
        end

        offset = offset + text_size.y
		gradient_inverted = not gradient_inverted
    end
end

-- EVENTS
events.createmove:set(function(cmd)
    local old_threat = current_threat
    current_threat = entity.get_threat(true)

    -- Update current velocity
    local_player = entity.get_local_player()
	current_velocity = local_player.m_vecVelocity

    -- Bhop detection
    local flags = entity.get_local_player().m_fFlags
    local on_ground = bit.band(flags, 1) ~= 0
    local local_player_in_bhop = (not on_ground) or cmd.in_jump

    -- Set defensive pitch
    rage.antiaim:override_hidden_pitch(89)

    -- Detect threat and TP
    if auto_tp_in_air_enabled then
        autoTP(local_player_in_bhop)
    end
end)

events.player_death:set(function(e)
    local me = entity.get_local_player()
    local dead_player = entity.get(e.userid, true)

    if me == dead_player then
        current_threat = nil
        tp_temp = 0
        tp_recharge_temp = 0
        is_recharging = false
    end
end)

events.render:set(function(ctx)
    scroll_offset = scroll_offset + (globals.frametime * animation_speed)
    ui.sidebar(get_gradient_text("StarTools", gradient_start, gradient_end, scroll_offset), "code")

    if debug_panel_toggle:get() then
        render_debug_panel(scroll_offset)
    end
end)