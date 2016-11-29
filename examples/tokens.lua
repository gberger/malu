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
3.14 123 abc.xyz  --[=[comment]=] 'xyz\n\x46' <= ! ~=
print('END!')
