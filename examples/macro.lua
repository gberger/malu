@loadfile "examples/_def_macro.lua"

print('Hello Lua.')

@macro dumb do
    print("I have a next function: ", next)

    if 1 == 1 then
        return "print(\"Things are okay.\")"
    else
        local i = 1
        while i < 5 do
            i = i + 1
        end
        return "print(\"The universe is broken!\")"
    end
end

@dumb
