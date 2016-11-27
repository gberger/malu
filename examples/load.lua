_M.using = function(next)
    assert(load(next))()
    print('dentro')

    return 'print("output da macro")'
end

assert(load([[
@using
print('comido pelo load')
]]))()
