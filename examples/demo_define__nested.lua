@loadfile "examples/_def_define.lua"

@define abc '10'
@define xyz '$1 + @abc() + $2'

print(@xyz(1, 2))
