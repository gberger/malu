@loadfile "examples/_macro_utils.lua"

-- local add = \x,y -> (x + y)
-- becomes:
-- local add = function(x, y) return x + y end
macros.enable_lambdas = function(next)
    local state = 'waiting'
    local param_names = {}
    local parens_stack = 0
    local body = ''

    return macros.token_filter(next, function(t, v)
        print(t, v)
        if state == 'waiting' then
            if t == '\\' then
                param_names = {}
                body = ''
                parens_stack = 0
                state = 'params'
            else
                return t, v
            end
        elseif state == 'params' then
            assert(t == '<name>', 'expected name token in lambda params list')
            param_names[#param_names+1] = v
            state = 'param_comma'
        elseif state == 'param_comma' then
            if t == ',' then
                state = 'params'
            elseif t == '-' then
                state = 'arrow'
            else
                assert(false, 'expected comma `,` or minus `-` token in lambda params list')
            end
        elseif state == 'arrow' then
            assert(t == '>', 'expected gt `>` token after lambda arrow')
            state = 'open_parens'
        elseif state == 'open_parens' then
            assert(t == '(', 'expected open parens `(` token after lambda arrow')
            parens_stack = 1
            state = 'body'
        elseif state == 'body' then
            if t == '(' then
                parens_stack = parens_stack + 1
            elseif t == ')' then
                parens_stack = parens_stack - 1
            end

            if parens_stack > 0 then
                body = body .. ' ' .. macros.output_token(t, v)
            else
                state = 'waiting'
               return '<lambda>',
                    'function (' .. table.concat(param_names, ',')
                            .. ') return ' .. body .. ' end'
            end
        end
    end)
end