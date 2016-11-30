macros.using = function(next_char)
    assert(load(next_char))()
    print('dentro')

    return 'print("output da macro")'
end

assert(load([[
@using
print('comido pelo load')
]]))()
