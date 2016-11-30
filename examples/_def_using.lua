macros.using = function(next_char)
    local token, value, name

    token, value = macros.next_token(next_char)
    token, name = macros.next_token(next_char)
    token, value = macros.next_token(next_char)

    local tbl = _G[name]
    local str = ''

    for k, v in pairs(tbl) do
        str = str .. ('local $field = $name.$field; '):gsub('$field', k):gsub('$name', name)
    end

    return str
end