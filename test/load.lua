print('testing load')


macros.inner = function(next_char)
    return 'abc'
end

macros.outer = function(next_char)
    return "@inner"
end

local f, e = load([[
abc = 5
assert(@outer + @inner == 10)
]])

assert(f)
f()
