x = 1

macros.e = function(next_char)
    x = next_char
end

local f,e = load[[
    @e
    print(x())
]]

if e then print(e) else f() end