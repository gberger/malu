macros.argparse = function(next)
    local parens = 0
    local brackets = 0
    local braces = 0
    local args = {}
    local current = ''
    local t, v
    t, v = macros.llex(next)
    assert(t == '(', 'unexpected token ' .. t .. ', expected parenthesis then a list of arguments')

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
        end

        assert(brackets >= 0, 'unexpected brackets mismatch')
        assert(braces >= 0, 'unexpected brackets mismatch')

        if t == ',' then
            if parens == 0 and brackets == 0 and braces == 0 then
                args[#args+1] = current
                current = ''
            else
                current = current .. v
            end
        elseif t == '<string>' then
            current = current .. "'" .. v .. "'"
        else
            current = current .. v
        end
        t, v = macros.llex(next)
    end
    if current ~= '' then
        args[#args+1] = current
    end

    return args
end