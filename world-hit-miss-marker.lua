--require modules
local interpolation = require("Interpolation")
--initialize vars
local properties = {
	ss = render.screen_size(),
	colors = {
        world = {
            normal = color(255, 255, 255, 255),
            headshot = color(255, 0, 0, 255),
			kill = color(255, 255, 255, 255)
        },
        miss = {
            normal = color(255, 100, 100, 255)
        }
    },
    lifetime = {
        screen = 1,
        world = 1,
        miss = 1
    },
    alpha_speed = {
        world = 50,
        miss = 50
    }
}
local world_hitmarker = {}
local world_missmarker = {}
local shapes = {
	cross = ui.get_icon("cross"),
	person = ui.get_icon("person-simple"),
	check = ui.get_icon("check"),
	crosshair = ui.get_icon("crosshairs"),
	xmark = ui.get_icon("xmark"),
	skull = ui.get_icon("skull"),
	wifi = ui.get_icon("wifi")
}
local font = render.load_font("Verdana", 14)
local miss_font = render.load_font("Verdana", 14)
--initialize menu
local world_group = ui.create("World Hitmarker")
local world_switch = world_group:switch("Enabled", true)
local world_shape = world_group:combo("Shape", shapes)
local world_hs_shape = world_group:combo("Headshots Shape", shapes)
local world_kill_shape = world_group:combo("Kills Shape", shapes)
local world_size = world_group:slider("Size", 1, 10, 3)
local world_lifetime = world_group:slider("Life time", 1, 50, 10, 0.1)
local world_fadetime = world_group:slider("Fade time", 1, 25, 15, 0.05)
local world_color = world_group:color_picker("Color", color(255, 255, 255, 255))
local world_hs_color = world_group:color_picker("Headshots Color", color(255, 255, 255, 255))
local world_kill_color = world_group:color_picker("Kills Color", color(255, 255, 255, 255))

local miss_group = ui.create("World Missmarker")
local miss_switch = miss_group:switch("Enabled", true)
local miss_shape = miss_group:combo("Shape", shapes, shapes.cross)
local miss_size = miss_group:slider("Size", 1, 10, 3)
local miss_lifetime = miss_group:slider("Life time", 1, 50, 10, 0.1)
local miss_fadetime = miss_group:slider("Fade time", 1, 25, 10, 0.05)
local miss_color = miss_group:color_picker("Color", color(255, 100, 100, 255))
--functions
local function render_shape(pos, hit)
	render.text(font, pos, hit.color, "c", hit.is_deadly and world_kill_shape:get() or (hit.is_hs and world_hs_shape:get() or world_shape:get()))
end
local function render_miss_shape(pos, miss)
	render.text(miss_font, pos, miss.color, "c", miss_shape:get())
end
local function handle_world_hitmarker(time)
    for i, hit in ipairs(world_hitmarker) do
        if time - hit.time > properties.lifetime.world then
            hit.target_alpha = 0
        end
        if hit.alpha == 0 then
            table.remove(world_hitmarker, i)
        end
    end
    for i, hit in ipairs(world_hitmarker) do
        hit.alpha = interpolation.interpolate(hit.alpha, hit.target_alpha, properties.alpha_speed.world)
        hit.color = hit.color:alpha_modulate(hit.alpha)
        local pos = render.world_to_screen(hit.pos)
        if pos ~= nil and world_switch:get() then
            render_shape(pos, hit)
        end
    end
end
local function handle_world_missmarker(time)
    for i, miss in ipairs(world_missmarker) do
        if time - miss.time > properties.lifetime.miss then
            miss.target_alpha = 0
        end
        if miss.alpha == 0 then
            table.remove(world_missmarker, i)
        end
    end
    for i, miss in ipairs(world_missmarker) do
        miss.alpha = interpolation.interpolate(miss.alpha, miss.target_alpha, properties.alpha_speed.miss)
        miss.color = miss.color:alpha_modulate(miss.alpha)
        local pos = render.world_to_screen(miss.pos)
        if pos ~= nil and miss_switch:get() then
            render_miss_shape(pos, miss)
        end
    end
end
-- register game events
events.aim_ack:set(function(shot)
    -- hit: state is nil and damage > 0
    if shot.state == nil and shot.damage > 0 and shot.aim then
        table.insert(world_hitmarker, {
            pos = shot.aim,
            time = globals.realtime,
            alpha = 255,
            target_alpha = 255,
            color = (not shot.target:is_alive()) and properties.colors.world.kill or (shot.hitgroup == 1 and properties.colors.world.headshot or properties.colors.world.normal),
            is_hs = shot.hitgroup == 1,
            is_deadly = not shot.target:is_alive()
        })
    -- miss: state is not nil
    elseif shot.state ~= nil and shot.aim then
        table.insert(world_missmarker, {
            pos = shot.aim,
            time = globals.realtime,
            alpha = 255,
            target_alpha = 255,
            color = properties.colors.miss.normal
        })
    end
end)
events.render:set(function()
    local time = globals.realtime
    handle_world_hitmarker(time)
    handle_world_missmarker(time)
end)
	
--register menu events
world_switch:set_callback(function(value)
	local visibility = value:get()
	world_shape:visibility(visibility)
	world_hs_shape:visibility(visibility)
	world_kill_shape:visibility(visibility)
	world_size:visibility(visibility)
	world_lifetime:visibility(visibility)
	world_fadetime:visibility(visibility)
	world_color:visibility(visibility)
	world_hs_color:visibility(visibility)
	world_kill_color:visibility(visibility)
end, true)
world_size:set_callback(function(value)
	font:set_size(value:get() + 10)
end, true)
world_lifetime:set_callback(function(value)
    properties.lifetime.world = value:get() / 10
end, true)
world_fadetime:set_callback(function(value)
    properties.alpha_speed.world = 255 / (value:get() / 20)
end, true)
world_color:set_callback(function(value)
    properties.colors.world.normal = value:get()
end, true)
world_hs_color:set_callback(function(value)
    properties.colors.world.headshot = value:get()
end, true)
world_kill_color:set_callback(function(value)
    properties.colors.world.kill = value:get()
end, true)

miss_switch:set_callback(function(value)
    local visibility = value:get()
    miss_shape:visibility(visibility)
    miss_size:visibility(visibility)
    miss_lifetime:visibility(visibility)
    miss_fadetime:visibility(visibility)
    miss_color:visibility(visibility)
end, true)
miss_size:set_callback(function(value)
    miss_font:set_size(value:get() + 10)
end, true)
miss_lifetime:set_callback(function(value)
    properties.lifetime.miss = value:get() / 10
end, true)
miss_fadetime:set_callback(function(value)
    properties.alpha_speed.miss = 255 / (value:get() / 20)
end, true)
miss_color:set_callback(function(value)
    properties.colors.miss.normal = value:get()
end, true)
