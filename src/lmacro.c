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
#include "lmacro.h"

#define lua_swap(L) lua_insert(L, -2)

/*
** This function will be closure-ed, receiving the LexState as an upvalue (in
** a light userdata), and passed to any macro. The macro can call it to
** obtain the next char.
*/
static int get_next_char_lua_closure(lua_State *L) {
  LexState *ls = lua_touserdata(L, lua_upvalueindex(1));
  char next_char[2] = {0, 0};

  if (ls->current == EOZ) {
    return 0;
  }

  if (ls->current == 10) {
    ls->current = 32;
  }

  next_char[0] = cast(char, ls->current);
  lua_pushstring(ls->L, next_char);

  next(ls);
  if (ls->current == EOZ) {
    (ls->z->n)++;
  }

  return 1;
}

/*
** updates ls->current by reading a character from the macro string
** at the top of the macro strings table (stack).
*/
void macro_next (LexState *ls) {
  size_t t_len;
  char const* str;
  lua_Integer str_index;
  size_t str_len;

  /* length of the macro string table, guaranteed to be >0 */
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
  ls->msi[t_len - 1] = cast(int, str_index + 1);

  /* verify if we reached the end of the string */
  if (ls->msi[t_len - 1] == (long long) str_len) {
    /* remove it from the table */
    lua_pushnil(ls->L);
    lua_seti(ls->L, ls->msti, cast(lua_Integer, t_len));

    if (t_len == 1) {
      /* table is now empty, pop it */
      ls->msti = 0;
      lua_pop(ls->L, 1);
    }
  }
}

/*
** called during llex, when ls->current == '@'
** reads a macro's name, calls it, and store its result in the
** macro strings table
*/
void read_macro (LexState *ls) {
  char next_char[2] = {0, 0};

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
    luaZ_resetbuffer(ls->buff);


    /* get function from _G._M[macro_name] */
    lua_getglobal(ls->L, "_M");
    lua_getfield(ls->L, -1, getstr(ts));
    lua_remove(ls->L, -2);

    if (!lua_isfunction(ls->L, -1)) {
      lua_pop(ls->L, 1);
      return lexerror(ls, "macro does not exist", 0);
    }

    /* create C closure with the LexState */
    lua_pushlightuserdata(ls->L, ls);
    lua_pushcclosure(ls->L, get_next_char_lua_closure, 1);

    /* call the macro with the closure as a parameter */
    lua_call(ls->L, 1, 1);

    /* if the function call returns a non-empty string,
       add it to the lex queue */
    if (lua_type(ls->L, -1) == LUA_TSTRING && lua_rawlen(ls->L, -1) > 0) {
      /* initialize macro string table if needed */
      if (ls->msti == 0) {
        lua_newtable(ls->L);
        lua_swap(ls->L);
        ls->msti = lua_gettop(ls->L) - 1;
      }

      /* macro_str = macro_str .. ls->current */
      next_char[0] = cast(char, ls->current);
      lua_pushstring(ls->L, next_char);
      lua_concat(ls->L, 2);

      /* push the macro_str to the end of the macro_table, initialize msi */
      lua_seti(ls->L, ls->msti,
               cast(lua_Integer, lua_rawlen(ls->L, ls->msti)) + 1);
      ls->msi[lua_rawlen(ls->L, ls->msti) - 1] = 0;

      next(ls);
    } else {
      /* discard the return */
      lua_pop(ls->L, 1);
    }
  }
}
