@loadfile "examples/_def_macro.lua"


@defmacro demo_argparse do
   print('Parsing args...')

   local args = macros.argparse(next_char)

   print('Printing args:')
   for i, arg in ipairs(args) do
       print(i, arg)
   end

   print()
end

@demo_argparse(
    abc.xyz,
    t[fn(1==2)],
    (function () return 5 end)(),
    function (a, b) local c,d = a,b end
)

@demo_argparse "str"

@demo_argparse {a=1, b=2}
