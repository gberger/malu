macros.enable_bang_not = function(next_char)
    return macros.token_filter(next_char, function(t, i)
        if t == '!' then
            return 'not'
        else
            return t, i
        end
    end)
end


load[[
  @enable_bang_not
  print(!false) --> true
  print(!!true) --> true
]]()
