@loadfile "examples/_macro_utils.lua"

macros.define = function(next)
    local token, macro_name = macros.llex(next)
    assert(token == '<name>')

    local token, macro_body = macros.llex(next)
    assert(token == '<string>')

    macros[macro_name] = function(next)
        local args = macros.argparse(next)

        local result = macro_body
        for i, arg in ipairs(args) do
            result = result:gsub(('$' .. i), arg)
        end

        return result
    end
end