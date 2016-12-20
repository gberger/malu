@dofile "samples/def_defmacro.lua"

@defmacro reverse_names do
    return macros.token_filter(next_char, function(t, v)
        if t == '<name>' then
            return t, v:reverse()
        else
            return t, v
        end
    end)
end

abc = 1

@reverse_names

tnirp(cba)
