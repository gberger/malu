function innermacro(next)
    return "abc"
end

function mymacro(next)
    print("Next token is: ")
    return ""
end

print("comeco")

f, e = load("abc=5; print(1 @mymacro)")
if e then print('Load error: ' .. e) end
if f then f() end

print("fim")
