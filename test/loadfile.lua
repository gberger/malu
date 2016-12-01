print('testing loadfile')


@loadfile "test/loadfile_aux.lua"

assert(@foo == 25)
