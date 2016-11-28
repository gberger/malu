_M.macro = function(next)
    local token, value, macro_name
    local macro_body = {"local next = ..."}

    token, macro_name = llex(next)
    assert(token == '<name>')

    token, value = llex(next)
    while not (token == '<name>' and value == 'endmacro') do
        if token == '<string>' then
            macro_body[#macro_body+1] = "'" .. value .. "'"
        else
            macro_body[#macro_body+1] = value
        end

        token, value = llex(next)
    end

    local fn, e = load(table.concat(macro_body, ' '))
    print(e)

    _M[macro_name] = function(next)
        fn(next)
    end
end

assert(load([[
@macro dumb
    if 1 == 1 then
        print('God is good.')
    else
        local i = 1
        while i < 5 do
            print('The universe is broken!')
            i = i + 1
        end
    end
endmacro

@dumb
]]))()
