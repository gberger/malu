t = {value = 1}

function add(a, b)
    return a + b
end

@define mult '(($1) * ($2) * ($3))'

print(@mult(add(t.value, t['value']), 2, 3))
