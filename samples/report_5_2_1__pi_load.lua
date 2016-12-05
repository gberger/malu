macros.pi = function(next_char)
  print('hello world')
  return '3.14159265359'
end


local f = load[[
  print(1 + @pi)
]]()
--> hello world

f()
--> 4.14159265359
