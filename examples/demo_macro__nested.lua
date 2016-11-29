@loadfile "examples/_def_macro.lua"

@macro inner do
    return 'abc'
end

@macro outer do
    return "@inner"
end

abc = 5
print(@outer)
