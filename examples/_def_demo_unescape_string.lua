@loadfile "examples/_macro_utils.lua"

macros.ues = function(next)
    local t, v = macros.llex(next)
    return "'" .. macros.unescape_string(v) .. "'"
end
