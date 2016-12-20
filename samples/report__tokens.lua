macros.print_tokens = function(next_char)
    local token, info

    print("token", "info")
    repeat
        token, info = macros.next_token(next_char)
        print(token, info)
    until token == nil
end

load[[
    @print_tokens
    <= ! ~= for while if end  -- short comment
    3.14 123 abc.xyz  --[=[comment]=] "str"
]]
