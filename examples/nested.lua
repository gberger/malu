@loadfile "examples/_def_macro.lua"

@macro inner
    return 'abc'
endmacro

@macro outer
    return "@inner"
endmacro

abc = 5
print(@outer)
