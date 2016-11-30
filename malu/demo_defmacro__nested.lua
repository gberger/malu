@loadfile "malu/_def_defmacro.lua"

@defmacro inner do
    return 'abc'
end

@defmacro outer do
    return "@inner"
end

abc = 5
print(@outer)
