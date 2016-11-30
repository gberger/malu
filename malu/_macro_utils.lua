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

macros.output_tokens = function(list)
    local result = {}
    for i, tv in ipairs(list) do
        result[i] = macros.output_token(tv[1], tv[2])
    end

    return table.concat(result, ' ')
end

macros.argparse = function(next_char)
    local parens = 0
    local brackets = 0
    local braces = 0
    local blocks = 0
    local args = {}
    local t, v

    -- first token
    t, v = macros.next_token(next_char)

    if t == '<string>' then
        -- fn "str"
        -- one string argument
        args[1] = {{t, v}}
    elseif t == '{' then
        -- fn {a=1, b=2}
        -- one table argument
        args[1] = {{t, v}}

        t, v = macros.next_token(next_char)
        while true do
            if t == '{' then
                braces = braces + 1
            elseif t == '}' then
                braces = braces - 1
            end

            args[1][#args[1]+1] = {t, v}

            if braces == -1 then
                break
            end
            t, v = macros.next_token(next_char)
        end
    elseif t == '(' then
        -- fn(a, t.xyz, 5)
        -- full arguments list
        local current = {}

        t, v = macros.next_token(next_char)
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
                args[#args+1] = current
                current = {}
            else
                current[#current+1] = {t, v}
            end

            t, v = macros.next_token(next_char)
        end
        if #current > 0 then
            args[#args+1] = current, ' ')
        end
    else
        print('bad args')
    end

    return args
end

macros.next_block = function(next_char)
    local t, v
    local stack = 1

    -- first token
    t, v = macros.next_token(next_char)
    assert(t == 'do', 'expected "do"')

    local body = {{t, v}}

    repeat
        t, v = macros.next_token(next_char)
        if t == 'function' or t == 'if' or t == 'do' then
            stack = stack + 1
        elseif t == 'end' then
            stack = stack - 1
        end

        body[#body+1] = {t, v}
    until stack == 0

    return body
end

macros.token_filter = function(next_char, filter)
    local t, v
    local output = {}

    t, v = macros.next_token(next_char)
    repeat
        output[#output+1] = macros.output_token(filter(t, v))
        t, v = macros.next_token(next_char)
    until t == nil

    return table.concat(output, ' ')
end
