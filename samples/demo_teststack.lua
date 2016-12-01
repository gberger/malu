calls = 0

macros.test = function(next_char)
    calls = calls + 1
    print(calls)
    return '  @test  '
end


load([[
@test
]])()
