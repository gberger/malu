print('testing macro_utils')


assert(macros)
dofile("malu/macro_utils.lua")


function assert_token_list(list)
    for i, token in ipairs(list) do
        assert(type(token) == 'table')
        assert(#token == 2)
    end
end

-----------------------------------------------------------

do
    print('--testing macros.create_next_char')
    local next_char = macros.create_next_char('abcdef')
    assert(next_char() == 'a')
    assert(next_char() == 'b')
    assert(next_char() == 'c')
    assert(next_char('z') == nil)
    assert(next_char() == 'z')
    assert(next_char() == 'd')
    assert(next_char() == 'e')
    assert(next_char() == 'f')
    assert(next_char() == nil)
    assert(next_char() == nil)
    assert(next_char() == nil)
end

-----------------------------------------------------------

do
    print('--testing macros.next_token')
    local next_char, tokens, t, v


    tokens = [[
        + - * / ^ < > = ; .
        ( ) [ ] { }
        and break do else elseif
        end false for function goto if
        in local nil not or repeat
        return then true until while
        // .. ... == >= <= ~=
        << >> ::
    ]]
    next_char = macros.create_next_char(tokens)
    for token in string.gmatch(tokens, "%S+") do
        t, v = macros.next_token(next_char)
        assert(t == token)
        assert(v == token)
    end

    tokens = [[ 10 1000 0 999999999999999999 ]]
    next_char = macros.create_next_char(tokens)
    for token in string.gmatch(tokens, "%S+") do
        t, v = macros.next_token(next_char)
        assert(t == '<integer>')
        assert(v == tonumber(token))
    end

    tokens = [[ 0.4 4.57e-3 0.3e12 5e+20 ]]
    next_char = macros.create_next_char(tokens)
    for token in string.gmatch(tokens, "%S+") do
        t, v = macros.next_token(next_char)
        assert(t == '<number>')
        assert(v == tonumber(token))
    end

    tokens = [[ name hello foo bar ]]
    next_char = macros.create_next_char(tokens)
    for token in string.gmatch(tokens, "%S+") do
        t, v = macros.next_token(next_char)
        assert(t == '<name>')
        assert(v == token)
    end
    
    tokens = " \"str\" 'str' [[str]] "
    next_char = macros.create_next_char(tokens)
    for token in string.gmatch(tokens, "%S+") do
        t, v = macros.next_token(next_char)
        assert(t == '<string>')
        assert(v == 'str')
    end
end

-----------------------------------------------------------

do
    print('--testing macros.next_block')
    local next_char = macros.create_next_char[[
        do
            local a = 1
            local b = 2
            if a > b then
                repeat
                    local f = function ( )
                        return 5
                    end
                until 1 == 1
            elseif a < 0 then
                while true do
                    a = 10
                    break
                end
            else
                for i = 1 , 10 do
                   a = 15
                end
            end
        end
    ]]
    local block = macros.next_block(next_char)

    assert(type(block) == 'table')
    assert(#block == 55)
    assert_token_list(block)
    assert(block[1][1] == 'do')
    assert(block[#block][1] == 'end')
end

-----------------------------------------------------------

do
    print('--testing macros.argparse')

    local test_argparse = function(str, nargs)
        local next_char = macros.create_next_char(str)
        local args = macros.argparse(next_char)
        assert(type(args) == 'table')
        assert(#args == nargs)
        for i, arg in ipairs(args) do
            assert_token_list(arg)
        end
    end

    test_argparse([[
        (
            abc.xyz,
            t[fn(1==2)],
            (function () return 5 end)(),
            function (a, b) local c,d = a,b end
        )
    ]], 4)

    test_argparse([[
        {
            a = 1,
            b = 2,
            c = abc.xyz,
            d = t[fn(1==2)],
            e = (function () return 5 end)(),
            f = function (a, b) local c,d = a,b end,
            g = {
                h = true
            }
        }
    ]], 1)

    test_argparse([[
        "str"
    ]], 1)
end

-----------------------------------------------------------

do
    print('--testing macros.output_token')

    assert(macros.output_token('do', 'do') == 'do')
    assert(macros.output_token('end', 'end') == 'end')
    assert(macros.output_token('if', 'if') == 'if')
    assert(macros.output_token('.', '.') == '.')
    assert(macros.output_token('<=', '<=') == '<=')

    assert(macros.output_token('<integer>', 100) == 100)
    assert(macros.output_token('<number>', -3.14) == -3.14)
    assert(macros.output_token('<name>', 'foo') == 'foo')
    assert(macros.output_token('<string>', 'hello') == "'hello'")

    assert(macros.output_token('<string>', '\n') == "'\\10'")
    assert(macros.output_token('<string>', '\\') == "'\\92'")
    assert(macros.output_token('<string>', '\"') == "'\\34'")
    assert(macros.output_token('<string>', '\'') == "'\\39'")
    assert(macros.output_token('<string>', '[')  == "'\\91'")
    assert(macros.output_token('<string>', ']')  == "'\\93'")
end

-----------------------------------------------------------

do
    print('--testing macros.output_tokens')
    assert(macros.output_tokens{
        {'do', 'do'},
        {'end', 'end'},
        {'if', 'if'},
        {'.', '.'},
        {'<=', '<='},
        {'<integer>', 100},
        {'<number>', -3.14},
        {'<name>', 'foo'},
        {'<string>', 'hello'}
    } == [[do end if . <= 100 -3.14 foo 'hello']])
end

-----------------------------------------------------------

do
    print('--testing macros.token_filter')
    local next_char = macros.create_next_char[[
        do 1 foo 'str' 3.14 end
    ]]
    local output = macros.token_filter(next_char, function(t, v)
        if t == '<name>' then
            return v:reverse()
        else
            return t, v
        end
    end)

    assert(output == [[do 1 oof 'str' 3.14 end]])
end
