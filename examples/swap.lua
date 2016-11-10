function next_until(next, char)
    local str = ''
    local curr = next()

    while curr ~= char do
        str = str .. curr
        curr = next()
    end

    return str
end


-- macro
function swap(next)
    next() -- skip opening parenthesis

    local args = next_until(next, ')')
    local a, b = args:match('([_%a][_%w]*)%s*,%s*([_%a][_%w]*)')

    return ('do local temp = $a; $a = $b; $b = temp; end'):gsub('$a', a):gsub('$b', b)
end


f,e=load([[
a = 1
b = 2
@swap(a, b)
print(a)
]])

print(e)
f()
