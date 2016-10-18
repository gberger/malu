function innermacro(v)
    return "abc"
end

function mymacro(v)
    return "@innermacro@ + 10"
end

print("comeco")

f, e = load("abc=5; print(1 + @mymacro@ )")

if e then
    print(e)
end

if type(f) == 'function' then
    f()
elseif type(f) == 'table' then
    for k, v in pairs(f) do
        print(k, v)
    end
else
   print('f não é function nem table, nil?')
end

print("fim")
