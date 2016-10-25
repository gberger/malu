/*
** $Id: lmacro.c $
** Lua Macros
** See Copyright Notice in lua.h
*/

#define lmacro_c

#include "lprefix.h"


#include "lua.h"

#include "lauxlib.h"
#include "lctype.h"
#include "ldebug.h"
#include "llex.h"



void read_macro (LexState *ls) {
  next(ls);

  /* macro name is `[A-Za-z][A-Za-z0-0]*` */
  if (!lislalpha(ls->current)) {
    lexerror(ls, "invalid macro", '@');
  } else {
    /* populate ls->buff until we run out of alphanum */
    do {
      save_and_next(ls);
    } while (lislalnum(ls->current));

    /* create string from the buffer */
    TString *ts = luaX_newstring(ls, luaZ_buffer(ls->buff),
                                 luaZ_bufflen(ls->buff));

    /* get global function from macro name and call it */
    lua_getglobal(ls->L, getstr(ts));
    lua_pushliteral(ls->L, "argumento");
    lua_call(ls->L, 1, 1);

    /* if the function call returns a non-empty string,
       add it to the lex queue */
    if (lua_type(ls->L, -1) == LUA_TSTRING && luaL_len(ls->L, -1) > 0) {
      lua_pushinteger(ls->L, 0);
    } else {
      /* pop the return */
      lua_pop(ls->L, 1);
    }

    luaZ_resetbuffer(ls->buff);
  }

  /* skip the ending '@' */
  next(ls);
}
