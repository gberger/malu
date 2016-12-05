@loadfile "malu/def_defmacro.lua"

@defmacro rt do
    local t = {'print(10)'}
    return ''
end

@rt
