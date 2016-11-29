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

  /* the first argument to malu_llex, should be a `next` function */
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
static int malu_llex(lua_State *L) {
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
** Generic argparse functiom
** =======================================================
*/

/*
** uses `malu_llex` to parse an input stream like (1, abc.xyz)
** into a table of arguments
**
** parameters:
** 1: a function, `next`
*/
static int malu_argparse(lua_State *L) {
  int args;
  const char *token, *value;
  int parens = 0, brackets = 0, braces = 0;

  /* args = {} */
  lua_newtable(L);
  args = lua_gettop(L);

  /* token, value = llex(next) */
  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_getfield(L, -1, "llex");
  lua_pushvalue(L, 1);  /* next */
  lua_call(L, 1, 2);  /* llex(next) */

  /* pop value */
  lua_pop(L, 1);

  /* assert(token == '(') */
  token = lua_tostring(L, -1);
  lua_pop(L, 1);
  lua_getglobal(L, "assert");
  lua_pushboolean(L, strcmp(token, "(") == 0);
  lua_call(L, 1, 0);

  /* token, value = llex(next) */
  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_getfield(L, -1, "llex");
  lua_pushvalue(L, 1);  /* next */
  lua_call(L, 1, 2);  /* llex(next) */
  value = lua_tostring(L, -1);
  lua_pop(L, 1);
  token = lua_tostring(L, -1);
  lua_pop(L, 1);

  /* current = '' */
  lua_pushstring(L, "");

  while (1) {
    if (strcmp(token, "(") == 0) {
      parens++;
    } else if (strcmp(token, ")") == 0) {
      parens--;
      if (parens == -1) {
        break;
      }
    } else if (strcmp(token, "[") == 0) {
      brackets++;
    } else if (strcmp(token, "]") == 0) {
      brackets--;
    } else if (strcmp(token, "{") == 0) {
      braces++;
    } else if (strcmp(token, "}") == 0) {
      braces++;
    }

    /*
      assert(brackets >= 0, 'unexpected brackets mismatch')
      assert(braces >= 0, 'unexpected brackets mismatch')
    */

    if (strcmp(token, ",") == 0) {
      if (parens == 0 && brackets == 0 && braces == 0) {
        /* args[#args+1] = current */
        lua_append(L, args);

        /* current = '' */
        lua_pushstring(L, "");
      } else {
        /* current = current .. value */
        lua_pushstring(L, value);
        lua_concat(L, 2);
      }
    } else if (strcmp(token, "<string>") == 0) {
      /* current = current .. "'" .. v .. "'" */
      lua_pushfstring(L, "'%s'", value);
      lua_concat(L, 2);
    } else {
      /* current = current .. v */
      lua_pushfstring(L, "%s", value);
      lua_concat(L, 2);
    }

    /* token, value = llex(next) */
    lua_getglobal(L, LUA_MACROLIBNAME);
    lua_getfield(L, -1, "llex");
    lua_pushvalue(L, 1);  /* next */
    lua_call(L, 1, 2);  /* llex(next) */
    value = lua_tostring(L, -1);
    lua_pop(L, 1);
    token = lua_tostring(L, -1);
    lua_pop(L, 2);
  }

  if (luaL_len(L, -1) > 0) {
    /* args[#args+1] = current */
    lua_append(L, args);
  }

  lua_pushvalue(L, args);

  return 1;
}

/* }====================================================== */


/*
** {======================================================
** @macro
** =======================================================
*/

/*
** upvalues:
** 1: a function, result of `load`, to be called with `next` as an argument
**
** parameters:
** 1: a function, `next`
*/
static int macro_closure(lua_State *L) {
  lua_pushvalue(L, lua_upvalueindex(1));
  lua_pushvalue(L, 1);
  lua_call(L, 1, 1);

  return 1;
}

static int malu_macro(lua_State *L) {
  int macro_body;
  const char *token, *value, *macro_name;

  /* macro_body = {"local next = ..."} */
  lua_newtable(L);
  macro_body = lua_gettop(L);
  lua_pushstring(L, "local next = ...");
  lua_append(L, macro_body);

  /* token, value = llex(next) */
  lua_getglobal(L, LUA_MACROLIBNAME);
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
  lua_getglobal(L, LUA_MACROLIBNAME);
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
    lua_getglobal(L, LUA_MACROLIBNAME);
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

  /* macros[macro_name] = fn */
  lua_pushcclosure(L, macro_closure, 1);

  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_swap(L);
  lua_setfield(L, -2, macro_name);

  /* return nil */
  lua_pushnil(L);
  return 1;
}

/* }====================================================== */

/*
** {======================================================
** @define
** =======================================================
*/

/*
** upvalues:
** 1: a string, the body of the define
**
** parameters:
** 1: a function, `next`
*/
static int define_closure(lua_State *L) {
  char dollar[3] = {'$', '0', 0};
  const char *result, *arg;
  int i;

  /* args = argparse(next) */
  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_getfield(L, -1, "argparse");
  lua_pushvalue(L, 1);  /* next */
  lua_call(L, 1, 1);

  /* result = macro_body */
  lua_pushvalue(L, lua_upvalueindex(1));
  result = lua_tostring(L, -1);
  lua_pop(L, 1);

  /* for i, arg in ipairs(args) */
  for (i = 1; i < 10; i++) {
    lua_rawgeti(L, -1, i);

    if (lua_isnil(L, -1)) {
      lua_pop(L, 1);
      break;
    }

    arg = lua_tostring(L, -1);
    lua_pop(L, 1);

    /* result = result:gsub(('$' .. i), arg) */
    dollar[1] = '0' + i;
    result = luaL_gsub(L, result, dollar, arg);
    lua_pop(L, 1);
  }

  lua_pushstring(L, result);
  return 1;
}

static int malu_define(lua_State *L) {
  const char *token, *define_name, *define_body;

  /* token, value = llex(next) */
  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_getfield(L, -1, "llex");
  lua_pushvalue(L, 1);  /* next */
  lua_call(L, 1, 2);  /* llex(next) */

  /* define_name = value */
  define_name = lua_tostring(L, -1);
  lua_pop(L, 1);

  /* assert(token == '<name>') */
  token = lua_tostring(L, -1);
  lua_pop(L, 1);
  lua_getglobal(L, "assert");
  lua_pushboolean(L, strcmp(token, "<name>") == 0);
  lua_call(L, 1, 0);

  /* token, value = llex(next) */
  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_getfield(L, -1, "llex");
  lua_pushvalue(L, 1);  /* next */
  lua_call(L, 1, 2);  /* llex(next) */

  /* define_body = value */
  define_body = lua_tostring(L, -1);
  lua_pop(L, 1);

  /* assert(token == '<string>') */
  token = lua_tostring(L, -1);
  lua_pop(L, 1);
  lua_getglobal(L, "assert");
  lua_pushboolean(L, strcmp(token, "<string>") == 0);
  lua_call(L, 1, 0);

  /* macros[define_name] = fn */
  lua_pushstring(L, define_body);
  lua_pushcclosure(L, define_closure, 1);

  lua_getglobal(L, LUA_MACROLIBNAME);
  lua_swap(L);
  lua_setfield(L, -2, define_name);

  /* return nil */
  lua_pushnil(L);
  return 1;
}

/* }====================================================== */



static const luaL_Reg macro_funcs[] = {
    {"llex", malu_llex},
    {"argparse", malu_argparse},
    {"macro", malu_macro},
    {"define", malu_define},
    {NULL, NULL}
};


LUAMOD_API int luaopen_macro (lua_State *L) {
  luaL_newlib(L, macro_funcs);
  return 1;
}

