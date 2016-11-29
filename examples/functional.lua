@define reduce [[
    (function()
        local res = $2
        for _i, _ in ipairs($1) do
            res = res $3 _
        end
        return res
    end)()
]]

@define sum '@reduce($1, 0, +)'
@define mul '@reduce($1, 1, *)'

local t = {1, 5, 10}

print(@reduce(t, 100, /))
print(@sum(t))
print(@mul(t))
