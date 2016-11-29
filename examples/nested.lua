@macro inner
    return 'abc'
endmacro

@macro outer
    return "@inner"
endmacro

abc = 5
print(@outer)
