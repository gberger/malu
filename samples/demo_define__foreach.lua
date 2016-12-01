@loadfile "malu/_def_define.lua"

@define foreach 'for _i, _ in ipairs(($1)) do $2 end'

@foreach({10,20,30}, print(_))
