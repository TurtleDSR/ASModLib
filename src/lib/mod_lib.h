#ifndef mod_lib_def
#define mod_lib_def

#ifdef __cplusplus
extern "C" {
#endif

//mod_lib.h

#include <stdbool.h>

#if defined(SWIG)
  #define DLLEXPORT
#elif defined(_WIN32)
  #ifdef DLLBUILD
    #define DLLEXPORT __declspec(dllexport)
  #else
    #define DLLEXPORT __declspec(dllimport)
  #endif
#else
  #define DLLEXPORT __attribute__ ((visibility ("default")))
#endif

/*
Context for an installation of a mod.
\warning Must be destroyed before runtime ends.
*/
typedef struct mod_lib_context_t mod_lib_context;
/*
Initializes library with a path to install scripts to.
\param scripts_path File path to Nuts/Scripts folder
\returns context to use the library through
\warning Once this function is used you must eventually use destroy() to avoid leaks
\warning Must be used before calling any other library functions
*/
DLLEXPORT mod_lib_context* mod_lib_init(const char* scripts_path);
/*
Frees all static library resources
\warning Must be used before program termination to avoid memory leaks
*/
DLLEXPORT void mod_lib_destroy(mod_lib_context* context);
/*
Installs a mod using the old zip format that Lemuura used to make his mods.
\param mod_path File path to mod .zip
\returns Status of installation
\warning Fails if init() has not been called
*/
DLLEXPORT bool install_mod_zip(mod_lib_context* context, const char* mod_path);
/*
Installs a mod using the asmod format developed by TurtleDSR
\param mod_path File path to mod .asmod
\returns Status of installation 
\warning Fails if init() has not been called
*/
DLLEXPORT bool install_mod_asmod(mod_lib_context* context, const char* mod_path);


#ifdef __cplusplus
}
#endif
#endif