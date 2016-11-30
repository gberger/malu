macros.load_next_char = function(next_char)
    assert(load(next_char))()
    print('dentro')

    return 'print("output da macro")'
end

assert(load([[
@load_next_char
print('comido pelo load')
]]))()
