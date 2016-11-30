dofile "examples/_macro_utils.lua"

macros.demo_readblock = function(next_char)
    print('Reading block...')
    local block = macros.readblock(next_char)
    print('Read block is:')
    print(block)
    return block
end