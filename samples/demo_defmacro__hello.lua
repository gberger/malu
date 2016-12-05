@loadfile "samples/def_defmacro.lua"

print('Hello Lua.')

@defmacro hello do
    print("I have a next_char function: ", next_char)

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

@hello
