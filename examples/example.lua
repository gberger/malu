function mymacro (v)
    print("Dentro da macro: " .. v)
    return "retorno"
end

print("comeco")
load("@mymacro")
print("meio")
