-- require modules
local interpolation = require("Interpolation")

-- constants
local SHAPES = {
    ui.get_icon("check"),
    ui.get_icon("person-simple"),
    ui.get_icon("xmark"),
    ui.get_icon("cross"),
    ui.get_icon("crosshairs"),
    ui.get_icon("skull"),
    ui.get_icon("wifi")
}

-- state
local properties = {
    colors = {
        hit = {
            normal = color(255, 255, 255, 255),
            headshot = color(255, 0, 0, 255),
            kill = color(255, 255, 255, 255)
        },
        miss = {
            marker = color(255, 100, 100, 255),
            reason = color(255, 100, 100, 255)
        }
    },
    lifetime = {
        hit = 1,
        miss = 1
    },
    alpha_speed = {
        hit = 50,
        miss = 50
    }
}

local hit_markers = {}
local miss_markers = {}

-- fonts
local hit_font = render.load_font("Verdana", 13, "abdi")
local miss_font = render.load_font("Verdana", 13, "abid")
local miss_reason_font = render.load_font("Verdana", 13, "aid")

-- menu: hitmarker
local hit_group = ui.create("World Hitmarker")
local hit_switch = hit_group:switch("Enabled")
local hit_shape = hit_group:combo("Shape", SHAPES)
local hit_hs_shape = hit_group:combo("Headshots Shape", SHAPES)
local hit_kill_shape = hit_group:combo("Kills Shape", SHAPES)
local hit_size = hit_group:slider("Size", 1, 10, 4)
local hit_lifetime = hit_group:slider("Lifetime", 1, 50, 10, 0.1)
local hit_fadetime = hit_group:slider("Fade time", 1, 25, 15, 0.05)
local hit_color = hit_group:color_picker("Color", color(255, 255, 255, 255))
local hit_hs_color = hit_group:color_picker("Headshots Color", color(255, 255, 255, 255))
local hit_kill_color = hit_group:color_picker("Kills Color", color(255, 255, 255, 255))

-- menu: missmarker
local miss_group = ui.create("World Missmarker")
local miss_switch = miss_group:switch("Enabled")
local miss_shape = miss_group:combo("Shape", SHAPES)
local miss_size = miss_group:slider("Size", 1, 10, 4)
local miss_lifetime = miss_group:slider("Lifetime", 1, 50, 10, 0.1)
local miss_fadetime = miss_group:slider("Fade time", 1, 25, 15, 0.05)
local miss_color = miss_group:color_picker("Color", color(255, 100, 100, 255))
local miss_reason_size = miss_group:slider("Reason Font Size", 6, 24, 12)
local miss_reason_color = miss_group:color_picker("Reason Color", color(255, 100, 100, 255))

-- rendering
local function render_hit_marker(pos, marker)
    local shape = marker.is_deadly and hit_kill_shape:get() or (marker.is_hs and hit_hs_shape:get() or hit_shape:get())
    render.text(hit_font, pos, marker.color, "c", shape)
end

local function render_miss_marker(pos, marker)
    render.text(miss_font, pos, marker.color, "c", miss_shape:get())
    if marker.reason then
        local icon_size = render.measure_text(miss_font, "c", miss_shape:get())
        local reason_pos =
            vector(
            pos.x + icon_size.x / 2 + 6,
            (pos.y - icon_size.y / 2) + ((miss_size:get() + 10) - miss_reason_size:get()) / 2
        )
		local reason_size = render.measure_text(miss_reason_font, "", marker.reason)
		render.shadow(reason_pos + vector(0, reason_size.y / 2), reason_pos + vector(reason_size.x, reason_size.y / 2), marker.reason_color:alpha_modulate(marker.alpha))
        render.text(miss_reason_font, reason_pos, marker.reason_color:alpha_modulate(marker.alpha), "", marker.reason)
    end
end

local function update_markers(markers, lifetime, alpha_speed, render_fn, enabled)
    local time = globals.realtime
    for i = #markers, 1, -1 do
        local m = markers[i]
        if time - m.time > lifetime then
            m.target_alpha = 0
        end
        if m.alpha == 0 then
            table.remove(markers, i)
        end
    end
    for _, m in ipairs(markers) do
        m.alpha = interpolation.interpolate(m.alpha, m.target_alpha, alpha_speed)
        m.color = m.color:alpha_modulate(m.alpha)
        if m.reason_color then
            m.reason_color = m.reason_color:alpha_modulate(m.alpha)
        end
        local pos = render.world_to_screen(m.pos)
        if pos ~= nil and enabled then
            render_fn(pos, m)
        end
    end
end

-- events
events.aim_ack:set(
    function(shot)
        if not shot.aim then
            return
        end

        if shot.state == nil and shot.damage > 0 then
            table.insert(
                hit_markers,
                {
                    pos = shot.aim,
                    time = globals.realtime,
                    alpha = 255,
                    target_alpha = 255,
                    color = not shot.target:is_alive() and properties.colors.hit.kill or
                        (shot.hitgroup == 1 and properties.colors.hit.headshot or properties.colors.hit.normal),
                    is_hs = shot.hitgroup == 1,
                    is_deadly = not shot.target:is_alive()
                }
            )
        elseif shot.state ~= nil then
            table.insert(
                miss_markers,
                {
                    pos = shot.aim,
                    time = globals.realtime,
                    alpha = 255,
                    target_alpha = 255,
                    color = properties.colors.miss.marker,
                    reason = shot.state,
                    reason_color = properties.colors.miss.reason
                }
            )
        end
    end
)

events.render:set(
    function()
        update_markers(
            hit_markers,
            properties.lifetime.hit,
            properties.alpha_speed.hit,
            render_hit_marker,
            hit_switch:get()
        )
        update_markers(
            miss_markers,
            properties.lifetime.miss,
            properties.alpha_speed.miss,
            render_miss_marker,
            miss_switch:get()
        )
    end
)

-- menu callbacks: hitmarker
hit_switch:set_callback(
    function(value)
        local v = value:get()
        hit_shape:visibility(v)
        hit_hs_shape:visibility(v)
        hit_kill_shape:visibility(v)
        hit_size:visibility(v)
        hit_lifetime:visibility(v)
        hit_fadetime:visibility(v)
        hit_color:visibility(v)
        hit_hs_color:visibility(v)
        hit_kill_color:visibility(v)
    end,
    true
)

hit_size:set_callback(
    function(value)
        hit_font:set_size(value:get() + 10)
    end,
    true
)

hit_lifetime:set_callback(
    function(value)
        properties.lifetime.hit = value:get() / 10
    end,
    true
)

hit_fadetime:set_callback(
    function(value)
        properties.alpha_speed.hit = 255 / (value:get() / 20)
    end,
    true
)

hit_color:set_callback(
    function(value)
        properties.colors.hit.normal = value:get()
    end,
    true
)

hit_hs_color:set_callback(
    function(value)
        properties.colors.hit.headshot = value:get()
    end,
    true
)

hit_kill_color:set_callback(
    function(value)
        properties.colors.hit.kill = value:get()
    end,
    true
)

-- menu callbacks: missmarker
miss_switch:set_callback(
    function(value)
        local v = value:get()
        miss_shape:visibility(v)
        miss_size:visibility(v)
        miss_lifetime:visibility(v)
        miss_fadetime:visibility(v)
        miss_color:visibility(v)
        miss_reason_size:visibility(v)
        miss_reason_color:visibility(v)
    end,
    true
)

miss_size:set_callback(
    function(value)
        miss_font:set_size(value:get() + 10)
    end,
    true
)

miss_lifetime:set_callback(
    function(value)
        properties.lifetime.miss = value:get() / 10
    end,
    true
)

miss_fadetime:set_callback(
    function(value)
        properties.alpha_speed.miss = 255 / (value:get() / 20)
    end,
    true
)

miss_color:set_callback(
    function(value)
        properties.colors.miss.marker = value:get()
    end,
    true
)

miss_reason_size:set_callback(
    function(value)
        miss_reason_font:set_size(value:get())
    end,
    true
)

miss_reason_color:set_callback(
    function(value)
        properties.colors.miss.reason = value:get()
    end,
    true
)
