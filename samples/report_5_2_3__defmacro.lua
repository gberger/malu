@loadfile "malu/def_defmacro.lua"

@defmacro foo do
  print(next_char)
  return '10'
end

print(@foo)
--> function: 0x1027dfcc2 (em tempo de análise léxica)
--> 10 (em tempo de execução)
