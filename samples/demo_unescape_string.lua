@loadfile "samples/def_defmacro.lua"


@defmacro demo_unescape_string do
    local token, info = macros.next_token(next_char)
    return "'" .. macros.unescape_string(info) .. "'"
end


print(@demo_unescape_string "hello \\ \a \b \f \n \r \t \v \" \' [[ ]] [=[ ]=] goodbye")
