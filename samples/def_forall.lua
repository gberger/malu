dofile "malu/macro_utils.lua"

macros.forall = function(next_char)
    local t, v
    local name
    local iterated = {}

    t, name = macros.next_token(next_char)
    assert(t == '<name>', 'expected <name>')

    t, v = macros.next_token(next_char)
    assert(t == 'in', 'expected "in"')

    t, v = macros.next_token(next_char)
    repeat
        iterated[#iterated+1] = {t, v}
        t, v = macros.next_token(next_char)
    until t == 'do'

    return ('for _, %s in ipairs(%s) do'):format(name, macros.output_tokens(iterated))
end
