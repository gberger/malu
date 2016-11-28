print('Hello Lua.')

@macro dumb
    if 1 == 1 then
        return "print(\"Things are okay.\")"
    else
        local i = 1
        while i < 5 do
            i = i + 1
        end
        return "print(\"The universe is broken!\")"
    end
endmacro

@dumb
