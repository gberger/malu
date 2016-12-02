macros.tokens = function(next_char)
  print("token", "value", "type(value)")
  for i=1,13 do
    local token, value = macros.next_token(next_char)
    print(token, value, type(value))
  end
end
