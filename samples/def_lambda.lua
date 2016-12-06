dofile "malu/macro_utils.lua"

-- local add = \x,y -> (x + y)
-- becomes:
-- local add = function(x, y) return x + y end
macros.enable_lambdas = function(next_char)
    local state = 1
    local param_names = {}
    local parens_stack = 0
    local body = {}

    return macros.token_filter(next_char, function(token, info)
        -- states:
        -- 1 = waiting
        -- 2 = param name
        -- 3 = param comma or `-`
        -- 4 = arrow `>`
        -- 5 = open body parens
        -- 6 = body
        
        if state == 1 then
            if token == '\\' then
                param_names = {}
                body = {}
                parens_stack = 0
                state = 2
            else
                return token, info
            end
        elseif state == 2 then
            assert(token == '<name>', 'expected name token in lambda params list')
            param_names[#param_names+1] = info
            state = 3
        elseif state == 3 then
            assert(token == ',' or token == '-', 'expected comma `,` or minus `-` token in lambda params list')
            if token == ',' then
                state = 2
            elseif token == '-' then
                state = 4
            end
        elseif state == 4 then
            assert(token == '>', 'expected gt `>` token after lambda arrow')
            state = 5
        elseif state == 5 then
            assert(token == '(', 'expected open parens `(` token after lambda arrow')
            parens_stack = 1
            state = 6
        elseif state == 6 then
            if token == '(' then
                parens_stack = parens_stack + 1
            elseif token == ')' then
                parens_stack = parens_stack - 1
            end

            if parens_stack > 0 then
                body[#body+1] = macros.output_token(token, info)
            else
                state = 1
                return '<literal>', 'function (' .. table.concat(param_names, ',')
                            .. ') return ' .. table.concat(body, ' ') .. ' end'
            end
        end
    end)
end