macros.inner = function(next_char)
    return 'abc'
end

macros.outer = function(next_char)
    return "@inner"
end

load([[
abc = 5
print(@outer + @outer)
]])()
