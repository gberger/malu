@loadfile "examples/_def_macro.lua"

@macro loader
    assert(load(next))()
    print('dentro')

    return 'print("output da macro")'
endmacro

@loader
print('comido pelo load')
