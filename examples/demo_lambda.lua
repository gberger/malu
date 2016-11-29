@loadfile "examples/_def_lambda.lua"


@enable_lambdas

local add = \x,y -> (x + y)

print(add(1, 2))
