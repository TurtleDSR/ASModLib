%module mod_lib
%{
#include "mod_lib.h"
%}

%nodefaultctor mod_lib_context_t;
%nodefaultctor mod_lib_context;

%rename(mod_lib_context) mod_lib_context_t;
%rename(mod_lib_context) mod_lib_context;

struct mod_lib_context_t {};

typedef struct mod_lib_context_t mod_lib_context;

%rename(init) mod_lib_init;
%rename(destroy) mod_lib_destroy;

%include "mod_lib.h"