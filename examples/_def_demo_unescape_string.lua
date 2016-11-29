@loadfile "examples/_macro_utils.lua"

macros.demo_unescape_string = function(next)
    local t, v = macros.llex(next)
    return "'" .. macros.unescape_string(v) .. "'"
end
