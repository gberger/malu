@loadfile "examples/_def_demo_next_block.lua"

@demo_next_block do
    local a = 1
    local b = 2
    if a > b then
        repeat
            local f = function()
                return 5
            end
        until 1 == 1
    elseif a < 0 then
        while true do
            a = 10
            break
        end
    else
        for i = 1, 10 do
           a = 15
        end
    end
end

