macros.enable_fn = function(next_char)
    return macros.token_filter(next_char, function(t, i)
        if t == '<name>' and i == 'fn' then
            return 'function'
        else
            return t, i
        end
    end)
end


load[[
  @enable_fn

  fn add(x, y)
    return x + y
  end


  print(add(1, 2))  --> 3
]]()
