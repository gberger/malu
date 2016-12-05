@loadfile "samples/def_defmacro.lua"

@defmacro using do
    local token, value, name

    assert(macros.next_token(next_char) == '(')
    token, name = macros.next_token(next_char)
    assert(macros.next_token(next_char) == ')')

    local tbl = _G[name]
    local str = ''

    for k, v in pairs(tbl) do
        str = str .. ('local %s = %s.%s; '):format(k, name, k)
    end

    return str
end


@using(math)

print(sin(5))
