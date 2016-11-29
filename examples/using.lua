@macro using
    local token, value, name

    token, value = _M.llex(next)  -- skip opening parens
    token, name = _M.llex(next)   -- argument
    token, value = _M.llex(next)  -- skip closing parens

    local tbl = _G[name]
    local str = ''

    for k, v in pairs(tbl) do
        str = str .. ('local $field = $name.$field; '):gsub('$field', k):gsub('$name', name)
    end

    return str
endmacro

@using(math)
print(sin(5))
