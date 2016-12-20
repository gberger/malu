@dofile "malu/def_define.lua"
@dofile "samples/def_forall.lua"

@define reduce [[
    (function()
        local res = $2
        @forall v in $1 do
            res = res $3 v
        end
        return res
    end)()
]]

@define sum '@reduce($1, 0, +)'
@define mul '@reduce($1, 1, *)'

local t = {1, 5, 10}
print(@reduce(t, 100, /))  --> 2.0
print(@sum(t))             --> 16
print(@mul(t))             --> 50
