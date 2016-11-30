macros.cube = function(next_char)
  next_char() -- skip opening parens
  local name = ''
  local current = next_char()

  repeat
    name = name .. current
    current = next_char()
  until current == ')'

  return name .. '*' .. name .. '*' .. name
end


load[[
  print(@cube(10))
]]()
