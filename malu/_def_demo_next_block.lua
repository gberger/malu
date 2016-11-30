dofile "malu/_macro_utils.lua"

macros.demo_next_block = function(next_char)
    print('Reading block...')
    local block = macros.next_block(next_char)
    print('Read block is:')
    print(macros.output_tokens(block))
    return block
end