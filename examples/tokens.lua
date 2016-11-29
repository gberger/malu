@macro tokens
    print(_M.llex(next))
    print(_M.llex(next))
    print(_M.llex(next))
    print(_M.llex(next))
    print(_M.llex(next))
    print(_M.llex(next))
    print(_M.llex(next))
    print(_M.llex(next))
    print(_M.llex(next))
endmacro

@tokens
3.14 123 abc.xyz  --[=[comment]=] 'xyz\n\x46' <= ! ~=
print('END!')
