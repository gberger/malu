print('testing define')


@loadfile "malu/def_define.lua"

@define abc '$2'
@define xyz '$1 + @abc(nil, $1 + 100) + $2'

assert(type(macros.abc == 'function'))
assert(type(macros.xyz == 'function'))
assert(@xyz(10, 20) == 140)
