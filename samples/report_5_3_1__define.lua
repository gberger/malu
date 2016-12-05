@loadfile "malu/def_define.lua"

@define foreach 'for _, $1 in ipairs($2) do $3 end'

@foreach(v, {10,20,30}, print(v))
-- equivalente a:
-- for _, v in ipairs({10, 20, 30}) do print(v) end

--> 10
--> 20
--> 30
