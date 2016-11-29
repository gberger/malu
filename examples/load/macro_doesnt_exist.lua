macros.abc = function(next)
    return ''
end

assert(load([[
@xyz
]]))()
