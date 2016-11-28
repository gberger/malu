_M.tokens = function(next)
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
end

assert(load([[
@tokens
3.14 123 abc.xyz  --[=[comment]=] 'xyz\n\x46' <= ! ~=
print('fim')
]]))()
