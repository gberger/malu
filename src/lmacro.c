/*
** $Id: lmacro.c $
** Lua Macros
** See Copyright Notice in lua.h
*/

#define lmacro_c

#include "lprefix.h"

#include <stdio.h>

#include "lua.h"

#include "lauxlib.h"
#include "lctype.h"
#include "ldebug.h"
#include "llex.h"
#include "lualib.h"
#include "lmacro.h"


/*
** This function will be closure-ed, receiving the LexState as an upvalue (in
** a light userdata), and passed to any macro. The macro can call it to
** obtain the next char.
*/
static int next_char_closure(lua_State *L) {
  LexState *ls = lua_touserdata(L, lua_upvalueindex(1));

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

  lua_pushstring(ls->L, cast(const char*, &ls->current));

  next(ls);
  if (ls->current == EOZ) {
    (ls->z->n)++;
  }

  return 1;
}

typedef struct ZioWrapperData {
  int reg_ref;
  size_t size;
  ZIO* prev_zio;
} ZioWrapperData;

static const char *zio_wrapper_reader(lua_State *L, void *ud, size_t *size) {
  ZioWrapperData *data = (ZioWrapperData*) ud;

  /* trying to fill but this reader has been used */
  if (data->size == 0) {
    /* if we still have the ref to the string, unref it */
    if (data->reg_ref > 0) {
      luaL_unref(L, LUA_REGISTRYINDEX, data->reg_ref);
      data->reg_ref = 0;
    }

    /* see if previous zio has a buffer left */
    if (data->prev_zio->n > 0) {
      *size = data->prev_zio->n;
      data->prev_zio->n = 0;
      return data->prev_zio->p;
    }

    /* call reader from previous zio */
    return data->prev_zio->reader(L, data->prev_zio->data, size);
  }

  *size = data->size;
  data->size = 0;

  /* get string from registry; don't unref it yet, it will still be used! */
  lua_rawgeti(L, LUA_REGISTRYINDEX, data->reg_ref);
  const char *str = lua_tostring(L, -1);
  lua_pop(L, 1);
  return str;
}

void init_reczio(LexState *ls) {
  ZioWrapperData* data = luaM_new(ls->L, ZioWrapperData);
  data->size = lua_rawlen(ls->L, -1);
  data->reg_ref = luaL_ref(ls->L, LUA_REGISTRYINDEX); /* pops str */
  data->prev_zio = ls->z;

  ZIO* new_zio = luaM_new(ls->L, ZIO);
  luaZ_init(ls->L, new_zio, zio_wrapper_reader, data);
  ls->z = new_zio;
}


/*
** called from call_macro, immediately after calling macro
** store its result in the macro strings table
*/
void save_substitution_string(LexState *ls) {
  /* if the function call returns a non-empty string, add to the lex queue */
  if (lua_type(ls->L, -1) == LUA_TSTRING && lua_rawlen(ls->L, -1) > 0) {
    if (ls->current != EOZ) {
      /* macro_str = macro_str .. ls->current */
      lua_pushstring(ls->L, cast(const char *, &ls->current));
      lua_concat(ls->L, 2);
    }

    init_reczio(ls);
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
