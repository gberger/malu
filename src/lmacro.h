/*
** $Id: lmacro.h $
** Lua Macros
** See Copyright Notice in lua.h
*/

#ifndef lmacro_h
#define lmacro_h

/* if we have a macro string table, and it's not empty */
#define has_active_macros(ls) (ls->msti != 0 && lua_rawlen(ls->L, ls->msti) > 0)

void macro_next (LexState *ls);
void read_macro (LexState *ls);


#endif