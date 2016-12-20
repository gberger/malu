print('testing macro_utils')


assert(macros)
dofile("malu/macro_utils.lua")


function assert_token_list(list)
    for i, token in ipairs(list) do
        assert(type(token) == 'table')
        assert(#token >= 1)
        if token[1] == '<name>' or token[1] == '<string>' or token[1] == '<number>' or token[1] == '<integer>' then
            assert(#token == 2)
        else
            assert(#token == 1)
        end
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
    local next_char, tokens, token, info


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
    for tk in string.gmatch(tokens, "%S+") do
        token, info = macros.next_token(next_char)
        assert(token == tk)
        assert(info == nil)
    end

    tokens = [[ 10 1000 0 999999999999999999 ]]
    next_char = macros.create_next_char(tokens)
    for tk in string.gmatch(tokens, "%S+") do
        token, info = macros.next_token(next_char)
        assert(token == '<integer>')
        assert(info == tonumber(tk))
    end

    tokens = [[ 0.4 4.57e-3 0.3e12 5e+20 ]]
    next_char = macros.create_next_char(tokens)
    for tk in string.gmatch(tokens, "%S+") do
        token, info = macros.next_token(next_char)
        assert(token == '<number>')
        assert(info == tonumber(tk))
    end

    tokens = [[ name hello foo bar ]]
    next_char = macros.create_next_char(tokens)
    for tk in string.gmatch(tokens, "%S+") do
        token, info = macros.next_token(next_char)
        assert(token == '<name>')
        assert(info == tk)
    end
    
    tokens = " \"str\" 'str' [[str]] "
    next_char = macros.create_next_char(tokens)
    for tk in string.gmatch(tokens, "%S+") do
        token, info = macros.next_token(next_char)
        assert(token == '<string>')
        assert(info == 'str')
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
    print('--testing macros.stringify_token')

    assert(macros.stringify_token('do', 'do') == 'do')
    assert(macros.stringify_token('end', 'end') == 'end')
    assert(macros.stringify_token('if', 'if') == 'if')
    assert(macros.stringify_token('.', '.') == '.')
    assert(macros.stringify_token('<=', '<=') == '<=')

    assert(macros.stringify_token('<integer>', 100) == 100)
    assert(macros.stringify_token('<number>', -3.14) == -3.14)
    assert(macros.stringify_token('<name>', 'foo') == 'foo')
    assert(macros.stringify_token('<string>', 'hello') == "'hello'")

    assert(macros.stringify_token('<string>', '\n') == "'\\10'")
    assert(macros.stringify_token('<string>', '\\') == "'\\92'")
    assert(macros.stringify_token('<string>', '\"') == "'\\34'")
    assert(macros.stringify_token('<string>', '\'') == "'\\39'")
    assert(macros.stringify_token('<string>', '[')  == "'\\91'")
    assert(macros.stringify_token('<string>', ']')  == "'\\93'")
end

-----------------------------------------------------------

do
    print('--testing macros.stringify_tokens')
    assert(macros.stringify_tokens{
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
