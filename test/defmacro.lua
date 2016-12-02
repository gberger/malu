print('testing defmacro')


@loadfile "malu/def_defmacro.lua"

@defmacro dm1 do
    assert(type(next_char) == 'function')
    return '10'
end

assert(type(macros.defmacro) ==  'function')
assert(@dm1 == 10)
