function innermacro(v)
    return "abc"
end

function mymacro(v)
    v()
    return "@innermacro@ + (function () return @innermacro@ end)() + @innermacro@"
end

print("comeco")

load("abc=5; print(1 + @mymacro@)")()

print("fim")
