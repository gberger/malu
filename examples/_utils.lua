function next_until(next, char)
    local str = ''
    local curr = next()

    while curr ~= char do
        str = str .. curr
        curr = next()
    end

    return str
end

function next_while_match(next, pattern)
    local str = ''
    local current = next()

    while string.match(current, pattern) do
        str = str .. current
        current = next()
    end

    return str, current
end
