@loadfile "examples/_macro_utils.lua"

macros.reverse_names = function(next)
    return macros.token_filter(next, function(t, v)
        if t == '<name>' then
            return t, v:reverse()
        else
            return t, v
        end
    end)
end