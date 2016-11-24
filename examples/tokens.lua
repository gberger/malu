function using(next, llex)
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
    print(llex(next))
end

assert(load([[
@using
3.14 123 abc 'xyz' <= ! ~=
]]))()
