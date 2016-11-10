function next_while_match(next, pattern)
    local str = ''
    local current = next()

    while string.match(current, pattern) do
        str = str .. current
        current = next()
    end

    return str, current
end

function reverse(next)
    next() -- skip opening parenthesis

    local name = next_while_match(next, '[_%w]')

    return name:reverse()
end

load([[
abc = 5
print(@reverse(cba))
]])()
