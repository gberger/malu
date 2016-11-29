@loadfile "examples/_def_macro.lua"


@macro tokens
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
endmacro

@tokens
3.14 123 abc.xyz  --[=[comment]=] "str \n" <= ! ~=
print('END!')
