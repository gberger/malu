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
static void tokenpushpair(lua_State *L, Token t) {
  if (t.token < FIRST_RESERVED) {
    /* name and value are the same: just the char, like '!', '=' etc */
    lua_pushfstring(L, "%c", t.token);
    lua_pushfstring(L, "%c", t.token);
  } else {
    /* name first, then value based on which token */
    lua_pushstring(L, TOKEN_NAME(t.token));
    if (t.token < TK_EOS) {
      /* name and value are still the same: 'and', 'for' etc */
      lua_pushstring(L, TOKEN_NAME(t.token));
    } else if (t.token == TK_EOS) {
      lua_pushnil(L);
    } else if (t.token == TK_FLT) {
      /* 3.14 */
      lua_pushnumber(L, t.seminfo.r);
    } else if (t.token == TK_INT) {
      /* 10 */
      lua_pushinteger(L, t.seminfo.i);
    } else if (t.token == TK_NAME || t.token == TK_STRING) {
      /* 'value' */
      lua_pushstring(L, getstr(t.seminfo.ts));
    }
  }
}

/*
** 'next_token' function.
** Receives a function that, when called repeatedly, should return strings
** corresponding to Lua source code.
** It will use that function as input for the internal `llex` function,
** and return the name and value of the first token that was read.
*/
static int malu_next_token(lua_State *L) {
  lua_Reader reader = read_from_next_char;
  const char *chunkname = "internal llex/next_token";
  Mbuffer buff;
  char pending[2] = {0,0};

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
  pending[0] = ls.current;
  lua_pushstring(L, pending);
  lua_call(L, 1, 0);

  tokenpushpair(L, ls.t);

  return 2;
}

/* }====================================================== */


static int malu_loadfile(lua_State *L) {
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
    {"loadfile", malu_loadfile},
    {NULL, NULL}
};


LUAMOD_API int luaopen_macro (lua_State *L) {
  luaL_newlib(L, macro_funcs);
  return 1;
}

