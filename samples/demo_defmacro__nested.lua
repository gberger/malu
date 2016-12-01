@loadfile "malu/_def_defmacro.lua"

@defmacro inner do
    return 'abc'
end

@defmacro outer do
    local abc = 5
    return tostring(@inner + 10) .. ' + xyz'
end

local xyz = 15
print(@outer)
