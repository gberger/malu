--- Reads the next do/end block in the input stream.
-- @param next_char The next_char function
-- @return A list of tokens, corresponding to the block
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

--- Reads arguments from a "function call" in the input stream.
-- Can handle arguments `(like, this)`, `{like = this}`, and `"like this"`.
-- @param next_char The next_char function
-- @return A list of arguments. Each argument is a list of tokens
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

--- Unescapes a string, adding escape sequences
-- @param str A string
-- @return A string that represents the string as it might appear on Lua code
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

--- Converts a token to a string that represents how it might appear on Lua code
-- @param token The name of the token, like "for" or "<name>"
-- @param info (Optional) Additional semantic information associated with
-- the token, such as a string or number
-- @return A string that represents how the token might appear on Lua code
macros.stringify_token = function(token, info)
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

--- Converts a list of tokens using stringify_token
-- @param list List of tokens, where each token is like {token, info}
-- @return A string that represents how the tokens might appear on Lua code
macros.stringify_tokens = function(list)
    local result = {}
    for i, ti in ipairs(list) do
        result[i] = macros.stringify_token(ti[1], ti[2])
    end

    return table.concat(result, ' ')
end

--- Filters the tokens obtained from next_char according to a filter function
-- @param next_char The next_char function
-- @param filter A function that will receive (token, info) and must return
-- another pair of (token, info), for each of the tokens in the input stream.
-- @return A string that represents the filtered input stream
macros.token_filter = function(next_char, filter)
    local token, info
    local filtered = {}

    token, info = macros.next_token(next_char)
    repeat
        filtered[#filtered +1] = {filter(token, info)}
        token, info = macros.next_token(next_char)
    until token == nil

    return macros.stringify_tokens(filtered)
end

--- Creates a function that simulates next_char, for testing purposes
-- The returned function, when called repeated times, returns each character
-- in sequence. If called with a character, adds that character to the front
-- of the queue.
-- @param str The string that represents the simulated input stream
-- @return A function with semantics identical to next_char
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
