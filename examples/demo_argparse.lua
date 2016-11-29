@loadfile "examples/_def_demo_argparse.lua"


@demo_argparse(
    abc.xyz,
    t[fn(1==2)],
    (function () return 5 end)(),
    function (a, b) local c,d = a,b end
)

@demo_argparse "str"

@demo_argparse {a=1, b=2}
