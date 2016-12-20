macros.stringify_token('for')               --> 'for'
macros.stringify_token('<=')                --> '<='
macros.stringify_token('<name>', 'foo')     --> 'foo'
macros.stringify_token('<integer>', 100)    --> '100'
macros.stringify_token('<number>', 3.5e-1)  --> '0.35'
local s = macros.stringify_token('<string>', '"hi" \n')
--> "'\\34hi\\34 \\10'"
print(s)  --> '\34hi\34 \10'


macros.stringify_tokens{
    {'for'},
    {'<name>', 'i'}
} --> 'for i'
