local exports = {}

tprint = function(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        else
            print(formatting .. tostring(v))
        end
    end
end

local is_number = function (value)
    return type(value) == "number"
end

local is_userdata = function (value)
    return type(value) == "userdata"
end

local is_color = function (value)
    return type(value) == "userdata" and getmetatable(value).__name == "sol.ImColor"
end

exports.interpolate = function (value, target_value, step)
    -- interpolate(value: number, target_value: number, step: number) -> number
    if is_number(value) and is_number(target_value) and is_number(step) then
        local direction = target_value - value
        if direction > 0 then 
            return math.min(value + step * globals.frametime, target_value)
        end
        return math.max(value - step * globals.frametime, target_value)
    end
    -- interpolate(value: color, target_value: color, step: color) -> color
    if is_color(value) and is_color(target_value) then
        if is_number(step) then
            return value:lerp(target_value, step)
        end
    end
    return value
end

return exports