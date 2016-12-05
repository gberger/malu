macros.cube = function(next_char)
  -- pula parêntese de abertura
  assert(next_char() == '(')

  -- a string do número dentro dos parênteses
  local num = ''


  -- o caractere atual
  local current = next_char()


  -- concatena à string do número até chegar
  -- no parênteses de fechamento
  repeat
    num = num .. current
    current = next_char()
  until current == ')'

  return ('(%s) * (%s) * (%s)'):format(num, num, num)
end

load[[
  print(@cube(10))
  -- equivalente a print((10) * (10) * (10))
]]()
--> 1000
