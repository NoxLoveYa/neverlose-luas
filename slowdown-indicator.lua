--require modules
local mouse_lib = require("Mouse")
local interpolation = require("Interpolation")

--initialize vars
local properties = {
	ss = render.screen_size(),
	position = vector(0, 0, 0),
	color = color(155, 155, 255, 255),
	bar_thickness = 4,
	offset = -100,
	spacing = 4,
	size = vector(0, 0),
	grabbed = false,
	mouse_offset = vector(0, 0),
	alpha = 0,
	target_alpha = 0,
	alpha_speed = 1
}
properties.position = properties.ss/2

--load ressources
local images = {
	warning_sign = render.load_image_from_file( 'materials/panorama/images/icons/ui/warning.svg')
}

--initialize menu
local group = ui.create("Slowdown indicator")
local color_picker = group:color_picker("Color", color(155, 155, 255, 255))
local animation_time = group:slider("Animation time", 1, 10)
local position = group:slider("Position", -500, 3000)
position:visibility(false)

--register menu events
color_picker:set_callback(function(value)
	properties.color = value:get()
end, true)

animation_time:set_callback(function(value)
	properties.alpha_speed = value:get() * 255 / 2
end, true)

position:set_callback(function(value)
	properties.position.y = value:get()
end, true)

--functions
local function render_slowdown(slowdown, render_bounds)
	if properties.alpha == 0 then return end
	--var
	local final_pos = properties.position + vector(0, properties.offset)
	--get text size
	local text = "Slowdown: "..math.floor(slowdown * 100).."%"
	local text_size = render.measure_text(4, "", text)
	--update size
	properties.size.x = text_size.x
	properties.size.y = images.warning_sign.height + properties.spacing + text_size.y + properties.spacing + properties.bar_thickness
	--render slowdown indicator
	render.texture(images.warning_sign, final_pos - vector(images.warning_sign.width/2 - 2, properties.size.y/2 - text_size.y/2 + properties.spacing - 1), vector(images.warning_sign.width + 3, images.warning_sign.height + 2), color(0, 0, 0, properties.alpha))
	render.texture(images.warning_sign, final_pos - vector(images.warning_sign.width/2, properties.size.y/2 - text_size.y/2 + properties.spacing), nil, properties.color:alpha_modulate(properties.alpha))
	render.text(4, final_pos - vector(properties.size.x/2, properties.size.y/2 - images.warning_sign.height - properties.spacing), color(235, 235, 255, properties.alpha), "", "Slowdown: "..math.floor(slowdown * 100).."%")
	render.rect(final_pos - vector(properties.size.x/2, -properties.size.y/2 + properties.bar_thickness), final_pos - vector(-properties.size.x/2, -properties.size.y/2), color(25, 25, 25, properties.alpha))
	render.rect(final_pos - vector(properties.size.x/2, -properties.size.y/2 + properties.bar_thickness), final_pos - vector(properties.size.x/2 - properties.size.x * slowdown - 1, -properties.size.y/2), properties.color:alpha_modulate(properties.alpha))
	render.shadow(final_pos - vector(properties.size.x/2, -properties.size.y/2 + properties.bar_thickness), final_pos - vector(properties.size.x/2 - properties.size.x * slowdown - 1, -properties.size.y/2), properties.color:alpha_modulate(properties.alpha), 25, 0, 0)
	--render bounds
	if render_bounds then
		render.rect_outline(final_pos - vector(properties.size.x/2, properties.size.y/2) - properties.spacing, final_pos - vector(-properties.size.x/2, -properties.size.y/2) + properties.spacing*1.5, color(255, 255, 255, properties.alpha))
	end
end

--register events
events.mouse_input:set(function(mouse)
	if not mouse.m1 then properties.grabbed = false; return end
	local in_bounds = mouse_lib.is_mouse_in_bounds(mouse.pos, properties.position + vector(0, properties.offset) - vector(properties.size.x/2, properties.size.y/2) - properties.spacing, properties.position + vector(0, properties.offset) + vector(properties.size.x/2, properties.size.y/2) + properties.spacing*1.5)
	if in_bounds.is_in_bounds and properties.grabbed == false then 
		properties.grabbed = true
		properties.mouse_offset = mouse.pos - properties.position
	end
	if properties.grabbed then
		properties.position.y = mouse.pos.y - properties.mouse_offset.y
		position:set(properties.position.y)
	end
end)

events.render:set(function(ctx)
	-- if menu is open and the indicator is grabbed, render snap line
	if ui.get_alpha() ~= 0.0 and properties.grabbed then
		render.line(vector(properties.ss.x/2, 0), vector(properties.ss.x/2, properties.ss.y), color(255, 255, 255, 255))
	end

	--get player and check if the handle is valid/alive
	local player = entity.get_local_player()
	if ui.get_alpha() <= 0.0 then
		if player == nil or not player:is_alive() then 
			properties.target_alpha = 0
		else
			if 1 - player.m_flVelocityModifier == 0 then
				properties.target_alpha = 0
			else
				properties.target_alpha = 255
			end
		end
	else
		properties.target_alpha = 255
	end

	--update alpha value
	properties.alpha = interpolation.interpolate(properties.alpha, properties.target_alpha, properties.alpha_speed)

	--render slowdown indicator
	if (ui.get_alpha() <= 0.0 and player ~= nil) then
    	render_slowdown(1 - player.m_flVelocityModifier, false)
	else
		render_slowdown(1, true)
	end
end)