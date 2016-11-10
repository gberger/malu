function innermacro(next)
    return "abc"
end

function mymacro(next)
    return "@innermacro + "
end

print("comeco")

f, e = load("abc=5; print(1 + @mymacro abc)")
if e then print('Load error: ' .. e) end
if f then f() end

print("fim")
