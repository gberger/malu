function innermacro(next)
    next() -- skip space

    local input = ''
    local current = next()
    local pattern = '[ _%w]'

    while string.match(current, pattern) do
        input = input .. current
        current = next()
    end

    return string.reverse(input) .. current
end

function mymacro(next)
    return "@innermacro"
end

print("comeco")

f, e = load("abc=5; print(1 + @mymacro cba)")
if e then print('Load error: ' .. e) end
if f then f() end

print("fim")