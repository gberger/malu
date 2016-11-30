@loadfile "examples/_def_defmacro.lua"


@defmacro tokens do
  for i=1,9 do
    local token, value = macros.next_token(next_char)
    print(token, value, type(value))
  end
end

@tokens 3e4
123
abc.xyz  --[=[comment]=] "str" <= ! ~=
print('END!')
