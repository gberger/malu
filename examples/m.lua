_M.m = function(next)
    print(_M)
end

assert(load([[
@m
]]))()
