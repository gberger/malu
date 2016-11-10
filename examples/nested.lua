function inner(next)
    return 'abc'
end

function outer(next)
    return "@inner"
end

load([[
abc = 5
print(@outer)
]])()
