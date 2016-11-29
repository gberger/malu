@loadfile "examples/_macro_utils.lua"

-- local add = \x,y -> (x + y)
-- becomes:
-- local add = function(x, y) return x + y end
macros.enable_lambdas = function(next)
    local state = 1
    local param_names = {}
    local parens_stack = 0
    local body = {}

    return macros.token_filter(next, function(t, v)
        -- states:
        -- 1 = waiting
        -- 2 = param name
        -- 3 = param comma or `-`
        -- 4 = arrow `>`
        -- 5 = open body parens
        -- 6 = body

        if state == 1 then
            if t == '\\' then
                param_names = {}
                body = {}
                parens_stack = 0
                state = 2
            else
                return t, v
            end
        elseif state == 2 then
            assert(t == '<name>', 'expected name token in lambda params list')
            param_names[#param_names+1] = v
            state = 3
        elseif state == 3 then
            if t == ',' then
                state = 2
            elseif t == '-' then
                state = 4
            else
                assert(false, 'expected comma `,` or minus `-` token in lambda params list')
            end
        elseif state == 4 then
            assert(t == '>', 'expected gt `>` token after lambda arrow')
            state = 5
        elseif state == 5 then
            assert(t == '(', 'expected open parens `(` token after lambda arrow')
            parens_stack = 1
            state = 6
        elseif state == 6 then
            if t == '(' then
                parens_stack = parens_stack + 1
            elseif t == ')' then
                parens_stack = parens_stack - 1
            end

            if parens_stack > 0 then
                body[#body+1] = macros.output_token(t, v)
            else
                state = 1
                return '<lambda>',
                    'function (' .. table.concat(param_names, ',')
                            .. ') return ' .. table.concat(body, ' ') .. ' end'
            end
        end
    end)
end