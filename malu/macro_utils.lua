macros.next_block = function(next_char)
    local token, info
    local stack = 1

    -- first token
    token, info = macros.next_token(next_char)
    assert(token == 'do', 'expected "do"')

    local body = {{token, info}}

    repeat
        token, info = macros.next_token(next_char)
        if token == 'function' or token == 'if' or token == 'do' then
            stack = stack + 1
        elseif token == 'end' then
            stack = stack - 1
        end

        body[#body+1] = {token, info}
    until stack == 0

    return body
end

macros.argparse = function(next_char)
    local parens = 0
    local brackets = 0
    local braces = 0
    local blocks = 0
    local args = {}
    local token, info

    -- first token
    token, info = macros.next_token(next_char)

    if token == '<string>' then
        -- fn "str"
        -- one string argument
        args[1] = {{ token, info }}
    elseif token == '{' then
        -- fn {a=1, b=2}
        -- one table argument
        args[1] = {{ token, info }}

        token, info = macros.next_token(next_char)
        while true do
            if token == '{' then
                braces = braces + 1
            elseif token == '}' then
                braces = braces - 1
            end

            args[1][#args[1]+1] = { token, info }

            if braces == -1 then
                break
            end
            token, info = macros.next_token(next_char)
        end
    elseif token == '(' then
        -- fn(a, t.xyz, 5)
        -- full arguments list
        local current = {}

        token, info = macros.next_token(next_char)
        while true do
            if token == '(' then
                parens = parens + 1
            elseif token == ')' then
                parens = parens - 1
                if parens == -1 then
                    break
                end
            elseif token == '[' then
                brackets = brackets + 1
            elseif token == ']' then
                brackets = brackets - 1
            elseif token == '{' then
                braces = braces + 1
            elseif token == '}' then
                braces = braces - 1
            elseif token == 'function' or token == 'if' or token == 'do' then
                blocks = blocks + 1
            elseif token == 'end' then
                blocks = blocks - 1
            end

            assert(brackets >= 0, 'unexpected brackets mismatch')
            assert(braces >= 0, 'unexpected brackets mismatch')
            assert(blocks >= 0, 'unexpected function/if/do/end blocks mismatch')

            if token == ',' and parens == 0 and brackets == 0 and braces == 0 and blocks == 0 then
                args[#args+1] = current
                current = {}
            else
                current[#current+1] = { token, info }
            end

            token, info = macros.next_token(next_char)
        end
        if #current > 0 then
            args[#args+1] = current
        end
    else
        print(token, info)
        assert(false, 'bad args!')
    end

    return args
end

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

macros.output_token = function(token, info)
    if token == nil or token == '<eof>' then
        return ''
    elseif token == '<string>' then
        return "'" .. macros.unescape_string(info) .. "'"
    elseif token == '<name>' or token == '<number>' or token == '<integer>' or token == '<literal>' then
        return info
    else
        return token
    end
end

macros.output_tokens = function(list)
    local result = {}
    for i, ti in ipairs(list) do
        result[i] = macros.output_token(ti[1], ti[2])
    end

    return table.concat(result, ' ')
end

macros.token_filter = function(next_char, filter)
    local token, info
    local output = {}

    token, info = macros.next_token(next_char)
    repeat
        token, info = filter(token, info)
        output[#output+1] = macros.output_token(token, info)
        token, info = macros.next_token(next_char)
    until token == nil

    return table.concat(output, ' ')
end

macros.create_next_char = function(str)
   return function(v)
       if v ~= nil then
           str = v .. str
           return
       end

       char = str:sub(1, 1)
       str = str:sub(2)

       if char == '' then return nil end
       return char
   end
end
