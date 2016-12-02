@loadfile "malu/def_defmacro.lua"

@defmacro enable_fn do
  return macros.token_filter(next_char, function(t, v)
    if t == '<name>' and v == 'fn' then
      return 'function', 'function'
    else
      return t, v
    end
  end)
end

@enable_fn

fn add(x, y)
  return x + y
end

print(type(add))  --> 'function'
print(add(1, 2))  --> 3
