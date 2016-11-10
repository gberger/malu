function next_until(next, char)
    local str = ''
    local curr = next()

    while curr ~= char do
        str = str .. curr
        curr = next()
    end

    return str
end

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
