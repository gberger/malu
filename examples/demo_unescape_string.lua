@loadfile "examples/_def_macro.lua"


@macro demo_unescape_string do
    local t, v = macros.llex(next)
    return "'" .. macros.unescape_string(v) .. "'"
end


print(@demo_unescape_string "hello \\ \a \b \f \n \r \t \v \" \' [[ ]] [=[ ]=] goodbye")
