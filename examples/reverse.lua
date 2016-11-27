dofile"examples/_utils.lua"

_M.reverse = function(next)
    next() -- skip opening parenthesis

    local name = next_while_match(next, '[_%w]')

    return name:reverse()
end

load([[
abc = 5
print(@reverse(cba))
]])()
