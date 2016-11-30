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
#include "lualib.h"
#include "lmacro.h"

#define lua_swap(L) lua_insert(L, -2)


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
** This function will be closure-ed, receiving the LexState as an upvalue (in
** a light userdata), and passed to any macro. The macro can call it to
** obtain the next char.
*/
static int next_char_closure(lua_State *L) {
  LexState *ls = lua_touserdata(L, lua_upvalueindex(1));
  char charstr[2] = {0, 0};

  /* if called with a char, use it as current and hold the current! */
  if (lua_gettop(L) > 0) {
    lua_assert(strlen(str) > 0);
    lua_assert(ls->hold == -1);
    const char *str = lua_tostring(L, 1);

    ls->hold = ls->current;
    ls->current = str[0];

    return 0;
  }


  if (ls->current == EOZ) {
    return 0;
  }

  if (ls->current == 10) {
    ls->current = 32;
  }

  charstr[0] = cast(char, ls->current);
  lua_pushstring(ls->L, charstr);

  next(ls);
  if (ls->current == EOZ) {
    (ls->z->n)++;
  }

  return 1;
}


/*
** called from call_macro, immediately after calling macro
** store its result in the macro strings table
*/
void save_substitution_string(LexState *ls) {
  char charstr[2] = {0, 0};

  /* if the function call returns a non-empty string, add to the lex queue */
  if (lua_type(ls->L, -1) == LUA_TSTRING && lua_rawlen(ls->L, -1) > 0) {
    /* initialize macro string table if needed */
    if (ls->msti == 0) {
      lua_newtable(ls->L);
      lua_swap(ls->L);
      ls->msti = lua_gettop(ls->L) - 1;
    }

    /* macro_str = macro_str .. ls->current */
    charstr[0] = cast(char, ls->current);
    lua_pushstring(ls->L, charstr);
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


/*
** called from read_macro, immediately after reading the macro name
** calls the macro and store its result in the macro strings table
*/
void call_macro(LexState *ls, TString *ts) {
  /* get function from macros[macro_name] */
  lua_getglobal(ls->L, LUA_MACROLIBNAME);
  lua_getfield(ls->L, -1, getstr(ts));
  lua_remove(ls->L, -2);

  if (!lua_isfunction(ls->L, -1)) {
    lua_pop(ls->L, 1);
    lua_pushfstring(ls->L, "macro %s does not exist", getstr(ts));
    const char* msg = lua_tostring(ls->L, -1);
    lua_pop(ls->L, 1);
    lexerror(ls, msg, TK_MACRO);
    return;
  }

  /* create C closure with the LexState */
  lua_pushlightuserdata(ls->L, ls);
  lua_pushcclosure(ls->L, next_char_closure, 1);

  /* call the macro with the closure as a parameter */
  lua_call(ls->L, 1, 1);

  save_substitution_string(ls);
}


/*
** called during llex, when ls->current == '@'
** reads a macro's name, calls it, and store its result in the
** macro strings table
*/
void read_macro (LexState *ls) {
  TString *ts;

  next(ls);

  /* macro name is `[A-Za-z][A-Za-z0-0]*` */
  if (!lislalpha(ls->current)) {
    lexerror(ls, "invalid macro", '@');
    return;
  }

  /* populate ls->buff until we run out of alphanum */
  do {
    save_and_next(ls);
  } while (lislalnum(ls->current));

  /* create string from the buffer */
  ts = luaX_newstring(ls, luaZ_buffer(ls->buff), luaZ_bufflen(ls->buff));
  luaZ_resetbuffer(ls->buff);

  /* call the macro */
  call_macro(ls, ts);
}
