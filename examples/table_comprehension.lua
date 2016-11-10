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
function T(next)
    next() -- skip opening curly braces

    local body = next_until(next, '}')

    local expr, name, looped = body:match('(.+)%s+for%s+([_%a][_%w]*)%s+in%s+(.+)')

    return ([[
        (function()
            local t = {}
            for index, $name in pairs($looped) do
                t[index] = $expr
            end
            return t
        end)()
    ]]):gsub('$expr', expr):gsub('$name', name):gsub('$looped', looped)
end


f,e=load([[
local nums = {1, 2, 3}
local squares = @T{num ^ 2 for num in nums}
print(#squares)
for k, v in ipairs(squares) do print(v) end
]])

print(e)
f()
