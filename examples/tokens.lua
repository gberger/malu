function tokens(next, llex)
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
3.14 123 abc  --[=[comment]=] 'xyz\n\x46' <= ! ~=
print('fim')
]]))()
