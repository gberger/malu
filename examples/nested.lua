_M.inner = function(next)
    return 'abc'
end

_M.outer = function(next)
    return "@inner"
end

load([[
abc = 5
print(@outer)
]])()
