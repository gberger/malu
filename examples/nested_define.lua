@loadfile "examples/_def_define.lua"


@define abc '10'
@define xyz '@abc()'

print(@xyz())