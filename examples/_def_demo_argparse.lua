@loadfile "examples/_macro_utils.lua"

macros.demo_argparse = function(next)
    print('Parsing args...')

    local args = macros.argparse(next)

    print('Printing args:')
    for i, arg in ipairs(args) do
        print(i, arg)
    end

    print()
end