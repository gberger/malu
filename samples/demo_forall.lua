@dofile "samples/def_forall.lua"

@forall x in {10, 20, 30} do
    print(x)   --> 10   20   30
end

local t = {40, 50, 60}
@forall x in t do
    print(x)   --> 40   50   60
end
