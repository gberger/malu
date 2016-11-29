macros.using = function(next)
    local token, value, name

    token, value = macros.llex(next)
    token, name = macros.llex(next)
    token, value = macros.llex(next)

    local tbl = _G[name]
    local str = ''

    for k, v in pairs(tbl) do
        str = str .. ('local $field = $name.$field; '):gsub('$field', k):gsub('$name', name)
    end

    return str
end