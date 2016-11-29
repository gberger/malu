@macro m
    local args = macros.argparse(next)
    for i, arg in ipairs(args) do
        print(i, arg)
    end
endmacro

@m(1, abc.xyz, fn(t['5']), (function(x) return x*2 end)(5), {1,'oi([{)]}',3}, print(5))
print('end')
