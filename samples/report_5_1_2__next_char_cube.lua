macros.cube = function(next_char)
  next_char() -- skip opening parens
  local exp = ''
  local current = next_char()

  repeat
    exp = exp .. current
    current = next_char()
  until current == ')'

  return exp .. '*' .. exp .. '*' .. exp
end

load[[
  print(@cube(10))
]]()
--> 1000
