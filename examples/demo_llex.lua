@loadfile "examples/_def_macro.lua"


@macro tokens do
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
    print(macros.llex(next))
end

@tokens 3.14 123 \abc.xyz  --[=[comment]=] "str \n" <= ! ~=
print('END!')
