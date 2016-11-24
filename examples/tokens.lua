function using(next, llex)
    llex(next)
end

assert(load([[
@using
xyz('fora')
]]))()
