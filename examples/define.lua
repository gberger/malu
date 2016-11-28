_M.define = function(next)
    local token, macro_name = llex(next)
    assert(token == '<name>')

    local token, macro_body = llex(next)
    assert(token == '<string>')

    _M[macro_name] = function(next)
        local args = {}
        local current = ''
        local t, v
        t, v = llex(next)
        assert(t == '(')

        t, v = llex(next)
        while t ~= ')' do
            if t == ',' then
                args[#args+1] = current
                current = ''
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
print(@mult( 1 + 1 , 2 , 3 ) )
]]))()
