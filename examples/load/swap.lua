dofile"examples/_utils.lua"

macros.swap = function(next)
    next() -- skip opening parenthesis

    local args = next_until(next, ')')
    local a, b = args:match('([_%a][_%w]*)%s*,%s*([_%a][_%w]*)')

    return ('do local temp = $a; $a = $b; $b = temp; end'):gsub('$a', a):gsub('$b', b)
end

load([[
a = 1
b = 2
@swap(a, b)
print(a)
]])()