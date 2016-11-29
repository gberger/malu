@loadfile "examples/_macro_utils.lua"

macros.demo_readblock = function(next)
    print('Reading block...')
    local block = macros.readblock(next)
    print('Read block is:')
    print(block)
    return block
end