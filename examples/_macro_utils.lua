macros.unescape_string = function(str)
    local chars = {
        "\\",
        "\a",
        "\b",
        "\f",
        "\n",
        "\r",
        "\t",
        "\v",
        "\"",
        "\'",
        "[",
        "]",
    }

    for i, char in ipairs(chars) do
        str = str:gsub('%' .. char, "\\" .. string.byte(char))
    end

    return str
end

macros.output_token = function(token, value)
    if token == nil or token == '<eof>' then
        return ''
    elseif token == '<string>' then
        return "'" .. macros.unescape_string(value) .. "'"
    else
        return value
    end
end

macros.argparse = function(next)
    local parens = 0
    local brackets = 0
    local braces = 0
    local blocks = 0
    local args = {}
    local current = {}
    local t, v

    -- first token
    t, v = macros.llex(next)

    if t == '<string>' then
        -- fn "str"
        -- one string argument
        args[1] = macros.output_token(t, v)
    elseif t == '{' then
        -- fn {a=1, b=2}
        -- one table argument
        args[1] = '{'

        t, v = macros.llex(next)
        while true do
            if t == '{' then
                braces = braces + 1
            elseif t == '}' then
                braces = braces - 1
            end

            args[1] = args[1] .. macros.output_token(t, v)

            if braces == -1 then
                break
            end
            t, v = macros.llex(next)
        end
    elseif t == '(' then
        -- fn(a, t.xyz, 5)
        -- full arguments list

        t, v = macros.llex(next)
        while true do
            if t == '(' then
                parens = parens + 1
            elseif t == ')' then
                parens = parens - 1
                if parens == -1 then
                    break
                end
            elseif t == '[' then
                brackets = brackets + 1
            elseif t == ']' then
                brackets = brackets - 1
            elseif t == '{' then
                braces = braces + 1
            elseif t == '}' then
                braces = braces - 1
            elseif t == 'function' or t == 'if' or t == 'do' then
                blocks = blocks + 1
            elseif t == 'end' then
                blocks = blocks - 1
            end

            assert(brackets >= 0, 'unexpected brackets mismatch')
            assert(braces >= 0, 'unexpected brackets mismatch')
            assert(blocks >= 0, 'unexpected function/if/do/end blocks mismatch')

            if t == ',' and parens == 0 and brackets == 0 and braces == 0 and blocks == 0 then
                args[#args+1] = table.concat(current, ' ')
                current = {}
            else
                current[#current+1] = macros.output_token(t, v)
            end

            t, v = macros.llex(next)
        end
        if #current > 0 then
            args[#args+1] = table.concat(current, ' ')
        end
    else
        print('bad args')
    end

    return args
end

macros.readblock = function(next)
    local t, v
    local stack = 1
    local body = {'do'}

    -- first token
    t, v = macros.llex(next)
    assert(t == 'do', 'expected "do"')

    repeat
        t, v = macros.llex(next)
        if t == 'function' or t == 'if' or t == 'do' then
            stack = stack + 1
        elseif t == 'end' then
            stack = stack - 1
        end

        body[#body+1] = macros.output_token(t, v)
    until stack == 0

    return table.concat(body, ' ')
end

macros.token_filter = function(next, filter)
    local t, v
    local output = {}

    t, v = macros.llex(next)
    repeat
        output[#output+1] = macros.output_token(filter(t, v))
        t, v = macros.llex(next)
    until t == nil

    return table.concat(output, ' ')
end
