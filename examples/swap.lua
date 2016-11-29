@define swap '$1, $2 = $2, $1'

a = 1
b = 2
@swap(a, b);
print(a)
