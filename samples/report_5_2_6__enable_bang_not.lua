@loadfile "malu/def_defmacro.lua"

@defmacro enable_bang_not do
  return macros.token_filter(next_char, function(t, v)
    if t == '!' then
      return 'not', 'not'
    else
      return t, v
    end
  end)
end

@enable_bang_not

print(!false)  --> true
print(!!true)  --> true
