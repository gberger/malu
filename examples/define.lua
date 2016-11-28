_M.define = function(next)
    local token, macro_name = llex(next)
    assert(token == '<name>')

    local token, macro_body = llex(next)
    assert(token == '<string>')

    _M[macro_name] = function(next)
        local parens = 0
        local brackets = 0
        local braces = 0
        local args = {}
        local current = ''
        local t, v
        t, v = llex(next)
        assert(t == '(', 'unexpected token ' .. t .. ', call this macro like @' .. macro_name .. '(arg1, ...)')

        t, v = llex(next)
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
print(@mult(add(1, 1), 2, 3))
]]))()
