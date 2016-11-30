@loadfile "malu/_def_define.lua"

@define foreach do for _i, _ in ipairs(($1)) do $2 end end

@foreach({10,20,30}, print(_))
