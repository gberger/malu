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
** Used as the lua_Reader function for the 'llex' function.
*/
static const char *read_from_next(lua_State *L, void *ud, size_t *size) {
  (void) ud;  /* unused */

  /* the first argument to luaB_llex, should be a `next` function */
  lua_pushvalue(L, 1);
  lua_call(L, 0, 1);

  /* if `next` returns nil, no more input to process */
  if (lua_isnil(L, -1)) {
    *size = 0;
    return NULL;
  }

  /* the return of `next` is the result of the reader */
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
** 'llex' function.
** Receives a function that, when called repeatedly, should return strings
** corresponding to Lua source code.
** It will use that function as input for the internal `llex` function,
** and return the name and value of the first token that was read.
*/
static int luaB_llex(lua_State *L) {
  lua_Reader reader = read_from_next;
  const char *chunkname = "internal llex";
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
  luaX_next(&ls);  /* read one token */
  L->top--;  /* remove scanner's table */

  pending[0] = ls.current;
  lua_pushstring(L, pending);
  lua_call(L, 1, 0);

  tokenpushpair(L, ls.t);


  return 2;
}

/* }====================================================== */



/*
** {======================================================
** @macro
** =======================================================
*/

static int macro_closure(lua_State *L) {
  lua_pushvalue(L, lua_upvalueindex(1));
  lua_pushvalue(L, 1);
  lua_call(L, 1, 1);

  return 1;
}

static int luaB_macro(lua_State *L) {
  int macro_body;
  const char *token, *value, *macro_name;

  /* macro_body = {"local next = ..."} */
  lua_newtable(L);
  macro_body = lua_gettop(L);
  lua_pushstring(L, "local next = ...");
  lua_append(L, macro_body);

  /* token, value = llex(next) */
  lua_getglobal(L, "_M");
  lua_getfield(L, -1, "llex");
  lua_pushvalue(L, 1);  /* next */
  lua_call(L, 1, 2);  /* llex(next) */

  /* macro_name = value */
  macro_name = lua_tostring(L, -1);
  lua_pop(L, 1);

  /* assert(token == '<name>') */
  token = lua_tostring(L, -1);
  lua_pop(L, 1);
  lua_getglobal(L, "assert");
  lua_pushboolean(L, strcmp(token, "<name>") == 0);
  lua_call(L, 1, 0);

  /* token, value = llex(next) */
  lua_getglobal(L, "_M");
  lua_getfield(L, -1, "llex");
  lua_pushvalue(L, 1);  /* next */
  lua_call(L, 1, 2);  /* llex(next) */
  value = lua_tostring(L, -1);
  token = lua_tostring(L, -2);
  lua_pop(L, 2);

  /* while not (token == '<name>' and value == 'endmacro') do */
  while(!(strcmp(token, "<name>") == 0 && strcmp(value, "endmacro") == 0)) {
    /* if token == '<string>' then */
    if (strcmp(token, "<string>") == 0) {
      /* macro_body[#macro_body+1] = "'" .. value .. "'" */
      lua_pushfstring(L, "'%s'", value);
      lua_append(L, macro_body);
    } else {
      /* macro_body[#macro_body+1] = value */
      lua_pushstring(L, value);
      lua_append(L, macro_body);
    }

    /* token, value = llex(next) */
    lua_getglobal(L, "_M");
    lua_getfield(L, -1, "llex");
    lua_pushvalue(L, 1);  /* next */
    lua_call(L, 1, 2);  /* llex(next) */
    value = lua_tostring(L, -1);
    token = lua_tostring(L, -2);
    lua_pop(L, 3);
  }


  /* local fn, e = load(table.concat(macro_body, ' ')) */
  lua_getglobal(L, "table");
  lua_getfield(L, -1, "concat");
  lua_pushvalue(L, macro_body);
  lua_pushstring(L, " ");
  lua_call(L, 2, 1);

  lua_getglobal(L, "load");
  lua_swap(L);
  lua_call(L, 1, 2);

  /* if e then */
  if (!lua_isnil(L, -1)) {
    /* throw e */
    lua_error(L);
    return 0;
  } else {
    /* discard e */
    lua_pop(L, 1);
  }

  /* _M[macro_name] = fn */
  lua_pushcclosure(L, macro_closure, 1);

  lua_getglobal(L, "_M");
  lua_swap(L);
  lua_setfield(L, -2, macro_name);

  lua_getglobal(L, "_M");
  lua_getfield(L, -1, "dumb");

  lua_pushnil(L);
  return 1;
}

/* }====================================================== */



static const luaL_Reg macro_funcs[] = {
    {"llex", luaB_llex},
    {"macro", luaB_macro},
    {NULL, NULL}
};


LUAMOD_API int luaopen_macro (lua_State *L) {
  luaL_newlib(L, macro_funcs);
  return 1;
}

