/*
** $Id: lmacrolib.c,v $
** Macro Library
** See Copyright Notice in lua.h
*/

#define lmacrolib_c
#define LUA_LIB

#include "lprefix.h"


#include <stdlib.h>
#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"

#include "llex.h"
#include "ltable.h"
#include "ldo.h"
#include "lstring.h"
#include "ltable.h"
#include "lzio.h"

#define lua_append(L,t) lua_seti(L,t, cast(lua_Integer, lua_rawlen(L, t)) + 1)
#define lua_swap(L) lua_insert(L, -2)

/*
** {======================================================
** Generic Lexer function
** =======================================================
*/

/*
** Used as the lua_Reader function for the 'next_token' function.
*/
static const char *read_from_next_char(lua_State *L, void *ud, size_t *size) {
  (void) ud;  /* unused */

  /* the first argument to malu_next_token, should be a `next_char` function */
  lua_pushvalue(L, 1);
  lua_call(L, 0, 1);

  /* if `next_char` returns nil, no more input to process */
  if (lua_isnil(L, -1)) {
    *size = 0;
    return NULL;
  }

  /* the return of `next_char` is the result of the reader */
  const char *str = lua_tostring(L, -1);
  lua_pop(L, 1);

  *size = strlen(str);
  return str;
}

/*
** Push the name of the token and its value.
** If applicable, the value is pushed compatible with the type of token
** (i.e., names and strings have their value pushed as strings,
** ints as ints, floats as floats)
*/
static int pushtoken(lua_State *L, Token t) {
  if (t.token < FIRST_RESERVED) {
    /* just the name, like '!', '=' etc */
    lua_pushfstring(L, "%c", t.token);
    return 1;
  }

  /* first the name, like 'for', 'function', or even '<string>' */
  lua_pushstring(L, TOKEN_NAME(t.token));

  /* then maybe info */
  if (t.token == TK_FLT) {
    lua_pushnumber(L, t.seminfo.r);   /* 3.14 */
    return 2;
  } else if (t.token == TK_INT) {
    lua_pushinteger(L, t.seminfo.i);  /* 10 */
    return 2;
  } else if (t.token == TK_NAME || t.token == TK_STRING) {
    lua_pushstring(L, getstr(t.seminfo.ts));   /* 'value' */
    return 2;
  }

  return 1;
}

/*
** 'next_token' function.
** Receives a function that, when called repeatedly, should return strings
** corresponding to Lua source code.
** It will use that function as input for the internal `llex` function,
** and return the name (and info, if any) of the first token that was read.
*/
static int malu_next_token(lua_State *L) {
  lua_Reader reader = read_from_next_char;
  const char *chunkname = "internal llex/next_token";
  Mbuffer buff;

  ZIO z;
  luaZ_init(L, &z, reader, NULL);

  LexState ls;
  ls.hold = -1;
  ls.h = luaH_new(L);  /* create table for scanner */
  sethvalue(L, L->top, ls.h);  /* anchor it */
  luaD_inctop(L);
  luaZ_initbuffer(L, &buff);
  ls.buff = &buff;
  luaX_setinput(L, &ls, &z, luaS_new(L, chunkname), zgetc((&z)));
  ls.t.token = llex(&ls, &ls.t.seminfo);  /* read one token */
  L->top--;  /* remove scanner's table */

  if (ls.t.token == TK_EOS) {
    return 0;
  }

  /* call next_char(ls.current), so it can hold this unused character */
  lua_pushstring(L, cast(const char*, &ls.current));
  lua_call(L, 1, 0);

  return pushtoken(L, ls.t);
}

/* }====================================================== */


static int malu_dofile(lua_State *L) {
  const char *token, *value;

  /* token, value = next_token(next_char) */
  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_getfield(L, -1, "next_token");
  lua_pushvalue(L, 1);  /* next_char */
  lua_call(L, 1, 2);  /* next_token(next_char) */

  /* define_name = value */
  value = lua_tostring(L, -1);
  lua_pop(L, 1);

  /* assert(token == '<name>') */
  token = lua_tostring(L, -1);
  lua_pop(L, 1);
  lua_getglobal(L, "assert");
  lua_pushboolean(L, strcmp(token, "<string>") == 0);
  lua_call(L, 1, 0);

  lua_getglobal(L, "dofile");
  lua_pushstring(L, value);
  lua_call(L, 1, 0);

  return 0;
}


static const luaL_Reg macro_funcs[] = {
    {"next_token", malu_next_token},
    {"dofile", malu_dofile},
    {NULL, NULL}
};


LUAMOD_API int luaopen_macro (lua_State *L) {
  luaL_newlib(L, macro_funcs);
  return 1;
}

