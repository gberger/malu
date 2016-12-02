macros.hello = function(next_char)
  print('hello world')
end


load[[
  @hello
]]
--> hello world
