@dofile "samples/def_lambda.lua"
@enable_lambdas


local add = \x,y -> (x + y)
-- equivalent to: 
-- local add = function(x, y) return x + y end

print(add(1, 2)) --> 3
