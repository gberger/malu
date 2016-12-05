@loadfile "samples/def_defmacro.lua"

@defmacro rt do
    local t = {'print(10)'}
    return t
end

@rt
--> error