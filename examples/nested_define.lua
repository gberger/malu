@loadfile "examples/_def_define.lua"

@define abc '10'
@define xyz '5 + @abc() + 5'

print(@xyz())
