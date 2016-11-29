macros.macro = function(next)
    local token, value, macro_name
    local macro_body = {"local next = ..."}

    token, macro_name = macros.llex(next)
    assert(token == '<name>')

    token, value = macros.llex(next)
    while not (token == '<name>' and value == 'endmacro') do
        if token == '<string>' then
            macro_body[#macro_body+1] = "'" .. value .. "'"
        else
            macro_body[#macro_body+1] = value
        end

        token, value = macros.llex(next)
    end

    local fn, e = load(table.concat(macro_body, ' '))

    macros[macro_name] = function(next)
        return fn(next)
    end
end
