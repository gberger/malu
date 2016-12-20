dofile "malu/macro_utils.lua"

macros.define = function(next_char)
    local token, macro_name = macros.next_token(next_char)
    assert(token == '<name>')

    local token, macro_body = macros.next_token(next_char)
    assert(token == '<string>')

    macros[macro_name] = function(nnext_char)
        local args = macros.argparse(nnext_char)

        local result = macro_body
        for i, arg in ipairs(args) do
            result = result:gsub(('$' .. i), macros.stringify_tokens(arg))
        end

        return result
    end
end