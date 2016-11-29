dofile("examples/_macro_utils.lua")

macros.macro = function(next)
    local token, value, macro_name

    token, macro_name = macros.llex(next)
    assert(token == '<name>', 'expected a name token')

    local macro_body = 'local next = ... ' .. macros.readblock(next)
    local fn, e = load(macro_body)

    assert(not e, e)

    macros[macro_name] = function(nnext)
        return fn(nnext)
    end
end
