_M.define = function(next)
    local token, macro_name = llex(next)
    assert(token == '<name>')

    local token, macro_body = llex(next)
    assert(token == '<string>')

    _M[macro_name] = function(next)
        local stack = {
            parens = 0,
            brackets = 0,
            braces = 0
        }
        local args = {}
        local current = ''
        local t, v
        t, v = llex(next)
        assert(t == '(')

        t, v = llex(next)
        while true do
            if t == '(' then
                stack.parens = stack.parens + 1
                current = current .. v
            elseif t == ')' then
                stack.parens = stack.parens - 1
                if stack.parens == -1 then
                    break
                end
                current = current .. v
            elseif t == '[' then
                stack.brackets = stack.brackets + 1
                current = current .. v
            elseif t == ']' then
                stack.brackets = stack.brackets - 1
                current = current .. v
            elseif t == '{' then
                stack.braces = stack.braces + 1
                current = current .. v
            elseif t == '}' then
                stack.braces = stack.braces - 1
                current = current .. v
            elseif t == ',' then
                if stack.parens == 0 and stack.brackets == 0 and stack.braces == 0 then
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
            t, v = llex(next)
        end
        if current ~= '' then
            args[#args+1] = current
        end

        local result = macro_body
        for i, arg in ipairs(args) do
            result = result:gsub(('$' .. i), arg)
        end

        return result
    end
end

assert(load([[
@define mult '(($1) * ($2) * ($3))'
function add(a, b)
    return a + b
end
print(@mult( add ( 1 , 1 ) , 2 , 3 ) )
]]))()
