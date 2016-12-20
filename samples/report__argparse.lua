macros.demo_argparse = function(next_char)
    local args = macros.argparse(next_char)
    for i, arg in ipairs(args) do
        print(i, macros.output_tokens(arg))
    end
end


load[[
  @demo_argparse(
      abc.xyz,
      t[fn(1==2)],
      (function () return 5 end)(),
      function (a, b) local c,d = a,b end
  )
  --> 1  abc . xyz
  --> 2  t [ fn ( 1 == 2 ) ]
  --> 3  ( function ( ) return 5 end ) ( )
  --> 4  function ( a , b ) local c , d = a , b end


  @demo_argparse "str"
  --> 1	  'str'

  @demo_argparse {a=1, b=2}
  --> 1	  { a = 1 , b = 2 }
]]
