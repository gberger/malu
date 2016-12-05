macros.output_token('for')               --> 'for'
macros.output_token('<=')                --> '<='
macros.output_token('<name>', 'foo')     --> 'foo'
macros.output_token('<integer>', 100)    --> '100'
macros.output_token('<number>', 3.5e-1)  --> '0.35'
local s = macros.output_token('<string>', '"hi" \n')
--> "'\\34hi\\34 \\10'"
print(s)  --> '\34hi\34 \10'


macros.output_tokens{
    {'for'},
    {'<name>', 'i'}
} --> 'for i'
