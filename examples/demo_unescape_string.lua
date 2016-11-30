@loadfile "examples/_def_macro.lua"


@defmacro demo_unescape_string do
    local t, v = macros.next_token(next_char)
    return "'" .. macros.unescape_string(v) .. "'"
end


print(@demo_unescape_string "hello \\ \a \b \f \n \r \t \v \" \' [[ ]] [=[ ]=] goodbye")
