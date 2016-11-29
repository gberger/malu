macros.inner = function(next)
    return 'abc'
end

macros.outer = function(next)
    return "@inner"
end

load([[
abc = 5
print(@outer)
]])()
