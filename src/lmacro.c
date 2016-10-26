/*
** $Id: lmacro.c $
** Lua Macros
** See Copyright Notice in lua.h
*/

#define lmacro_c

#include "lprefix.h"

#include <stdio.h>

#include "lua.h"

#include "lctype.h"
#include "ldebug.h"
#include "llex.h"


/* This function will be closure-ed, receiving the LexState as an upvalue (in
 * a light userdata), and passed to any macro. The macro can call it to
 * obtain the next token. */
static int get_next_token_closure(lua_State *L) {
  LexState *ls = lua_touserdata(L, lua_upvalueindex(1));
  printf("I am in C. The current is: %c\n", ls->current);
  return 0;
}


void macro_next (LexState *ls) {
  size_t t_len;
  char const* str;
  lua_Integer str_index;
  size_t str_len;

  t_len = lua_rawlen(ls->L, ls->msti);

  /* put the last string at the top of the stack */
  lua_geti(ls->L, ls->msti, cast(lua_Integer, t_len));

  /* get it from the stack */
  str = lua_tolstring(ls->L, -1, &str_len);
  lua_pop(ls->L, 1);

  /* get the index we're at in this string */
  str_index = ls->msi[t_len - 1];

  /* store the char at that index, also increment the index */
  ls->current = str[str_index];

  str_index++;
  ls->msi[t_len - 1] = cast(int, str_index);

  if (ls->msi[t_len - 1] == (long long) str_len) {
    /* reached the end of the string, remove it from the table */
    lua_pushnil(ls->L);
    lua_seti(ls->L, ls->msti, cast(lua_Integer, t_len));

    if (t_len == 1) {
      /* table is now empty, pop it */
      ls->msti = 0;
      lua_pop(ls->L, 1);
    }
  }
}

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

    /* initialize macro string table if needed */
    if (ls->msti == 0) {
      lua_newtable(ls->L);
      ls->msti = lua_gettop(ls->L);
    }

    /* get global function from macro name */
    lua_getglobal(ls->L, getstr(ts));

    /* create C closure with the LexState */
    lua_pushlightuserdata(ls->L, ls);
    lua_pushcclosure(ls->L, get_next_token_closure, 1);

    /* call the macro with the closure as a parameter */
    lua_call(ls->L, 1, 1);

    /* if the function call returns a non-empty string,
       add it to the lex queue */
    if (lua_type(ls->L, -1) == LUA_TSTRING && lua_rawlen(ls->L, -1) > 0) {
      /* push the macro_str to the end of the macro_table, initialize msi */
      lua_seti(ls->L, ls->msti,
               cast(lua_Integer, lua_rawlen(ls->L, ls->msti)) + 1);
      ls->msi[lua_rawlen(ls->L, ls->msti) - 1] = 0;
    } else {
      /* discard the return */
      lua_pop(ls->L, 1);
    }

    luaZ_resetbuffer(ls->buff);
  }

  /* skip the ending '@' */
  next(ls);
}
