--initialize vars
local properties = {
    ss = render.screen_size(),
    color = color(255, 255, 255, 255),
    color2 = color(255, 255, 255, 125),
    inverted = false,
    --offset = vector(length, spacing, thickness)
    offset = vector(10, 4, 1),
    t_shape = false,
    target_alpha = 0,
    alpha = 0,
    alpha_speed = 1
}

--initialize menu
local group = ui.create("Custom Scope")
local color_picker = group:color_picker("Main Color", color(155, 155, 255, 255))
local color_picker2 = group:color_picker("Second Color", color(155, 155, 255, 125))
local animation_time = group:slider("Animation time", 1, 15)
local inverted = group:switch("Inverted", false)
local t_shape = group:switch("T shape", false)
local length = group:slider("Length", 1, 100)
local thickness = group:slider("Thickness", 1, 10)
local spacing = group:slider("Spacing", 1, 150)

--register menu events
color_picker:set_callback(function(value)
	properties.color = value:get()
end, true)

color_picker2:set_callback(function(value)
	properties.color2 = value:get()
end, true)

animation_time:set_callback(function(value)
	properties.alpha_speed = value:get() * 255 / 1.25
end, true)

inverted:set_callback(function(value)
    properties.inverted = value:get()
end, true)

t_shape:set_callback(function(value)
    properties.t_shape = value:get()
end, true)

length:set_callback(function(value)
    properties.offset.x = value:get()
end, true)

thickness:set_callback(function(value)
    properties.offset.z = value:get() - 1
end, true)

spacing:set_callback(function(value)
    properties.offset.y = value:get()
end, true)

--functions
local function determine_alpha()
    local player = entity.get_local_player()
    if not player or not player:is_alive() then
        properties.target_alpha = 0
    else
        if player.m_bIsScoped then
            properties.target_alpha = 255
        else
            properties.target_alpha = 0
        end
    end
end

local function update_alpha()
	local direction = properties.target_alpha - properties.alpha
	if direction > 0 then
		properties.alpha = math.min(properties.alpha + properties.alpha_speed * globals.frametime, properties.target_alpha)
	elseif direction < 0 then
		properties.alpha = math.max(properties.alpha - properties.alpha_speed * globals.frametime, properties.target_alpha)
	end
end

local function draw_scope()
    --get colors
    local color = properties.inverted and properties.color2 or properties.color
    local color2 = properties.inverted and properties.color or properties.color2

    --calculate alpha
    color = color:alpha_modulate(properties.alpha * color.a / 255)
    color2 = color2:alpha_modulate(properties.alpha * color2.a / 255)

    --render scope
    local pos = properties.ss / 2
    local length = properties.offset.x
    local spacing = properties.offset.y
    local thickness = properties.offset.z

    --render top
    if (not properties.t_shape) then
        render.gradient(vector(pos.x - thickness/2,  pos.y - spacing - length), vector(pos.x + thickness/2 + 1,  pos.y - spacing), color, color, color2, color2)
    end
    --render right
    render.gradient(vector(pos.x + spacing, pos.y - thickness/2), vector(pos.x + spacing + length, pos.y + thickness/2 + 1), color2, color, color2, color)
    --render bottom
    render.gradient(vector(pos.x - thickness/2, pos.y + spacing), vector(pos.x + thickness/2 + 1, pos.y + spacing + length), color2, color2, color, color)
    --render left
    render.gradient(vector(pos.x - spacing - length, pos.y - thickness/2), vector(pos.x - spacing, pos.y + thickness/2 + 1), color, color2, color, color2)
end

--register events
events.render:set(function(ctx)
    determine_alpha()
    update_alpha()
    draw_scope()
end)