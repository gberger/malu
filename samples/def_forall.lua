dofile "malu/macro_utils.lua"

macros.forall = function(next_char)
    local token, info
    local name
    local iterated = {}

    token, name = macros.next_token(next_char)
    assert(token == '<name>', 'expected <name>')

    token, info = macros.next_token(next_char)
    assert(token == 'in', 'expected "in"')

    token, info = macros.next_token(next_char)
    repeat
        iterated[#iterated+1] = { token, info }
        token, info = macros.next_token(next_char)
    until token == 'do'

    return ('for _, %s in ipairs(%s) do'):format(name, macros.output_tokens(iterated))
end
