function using(next, llex)
    llex()
end

assert(load([[
@using
print('fora')
]]))()
