macros.pi = function(next_char)
  return '3.14159265359'
end


load[[
  print(1 + @pi)
]]()
--> 4.14159265359