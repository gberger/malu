@loadfile "samples/def_lambda.lua"
@enable_lambdas

local add = \x,y -> (x + y)
local add3 = \x,y,z -> (add(add(x, y), z))

print(add3(1, 2, 3)) --> 6

