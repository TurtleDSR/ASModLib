#ifndef mod_install_def
#define mod_install_def

#ifdef __cplusplus
extern "C" {
#endif


//mod_install.h
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "zip.h"

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
Initializes library with a path to install scripts to
\param scripts_path File path to Nuts/Scripts folder
\warning Must be used before calling any otehr library functions
*/
DLLEXPORT void init(const char* scripts_path);
/*
Installs a mod using the old zip format that Lemuura used to make his mods.
\param mod_path File path to mod .zip
\returns Status of installation
\warning Fails if init() has not been called
*/
DLLEXPORT bool install_mod_zipformat(const char* mod_path);
/*
Installs a mod using the asmod format developed by TurtleDSR
\param mod_path File path to mod .asmod
\returns Status of installation 
\warning Fails if init() has not been called
*/
DLLEXPORT bool install_mod_asmodformat(const char* mod_path);


#ifdef __cplusplus
}
#endif
#endif