print('testing next_char')

macros.nc = function(next_char)
    assert(next_char() == ' ')
    assert(next_char() == '1')
    assert(next_char() == ' ')
    assert(next_char() == '2')
    assert(next_char() == ' ')
    assert(next_char() == '3')
    assert(next_char() == ' ')
    assert(next_char() == 'a')
    assert(next_char() == ' ')
    assert(next_char() == 'b')
    assert(next_char() == ' ')
    assert(next_char() == 'c')
    assert(next_char() == '\32')
    assert(next_char() == nil)
    assert(next_char() == nil)
    assert(next_char() == nil)
end

local f, e = load([[
    local x = 1
    @nc 1 2 3 a b c
]])

assert(f, e)
f()