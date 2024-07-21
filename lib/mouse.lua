local export = {}

export.is_mouse_in_bounds = function(mouse_pos, bounds_min, bounds_max)
    local is_in_bounds = mouse_pos.x >= bounds_min.x and mouse_pos.x <= bounds_max.x and mouse_pos.y >= bounds_min.y and mouse_pos.y <= bounds_max.y
    local mouse_offset = mouse_pos - bounds_min
    return {is_in_bounds = is_in_bounds, mouse_offset = mouse_offset}
end

return export