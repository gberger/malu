dofile"examples/_utils.lua"

function using(next)
    next() -- skip opening parenthesis

    local name = next_until(next, ')')
    local tbl = _G[name]
    local str = ''

    for k, v in pairs(tbl) do
        str = str .. ('local $field = $name.$field; '):gsub('$field', k):gsub('$name', name)
    end

    return str
end

load([[
@using(math)
print(sin(5))
]])()
