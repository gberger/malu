dofile "malu/macro_utils.lua"

macros.defmacro = function(next_char)
    local token, value, macro_name

    token, macro_name = macros.next_token(next_char)
    assert(token == '<name>', 'expected a name token')

    local macro_body = 'local next_char = ... ' .. macros.output_tokens(macros.next_block(next_char))

    local fn, e = load(macro_body)
    assert(not e, e)
    macros[macro_name] = fn
end
