#include "mod_install.h"

static char* scripts_path = NULL;

void init(const char* script_path) {
  if(scripts_path != NULL) free(scripts_path);

  #ifdef _WIN32
    scripts_path = _strdup(script_path);
  #else
    scripts_path = strdup(script_path);
  #endif
}

bool install_mod_zipformat(const char* mod_path) {
  if(scripts_path == NULL || mod_path == NULL) return false;

  printf("[C-DEBUG] Opening: %s into: %s\n", mod_path, scripts_path);

  if(zip_extract(mod_path, scripts_path, NULL, NULL) == 0) return true;

  return false;
}

bool install_mod_asmodformat(const char* mod_path) {
  /*UNIMPLEMENTED*/
}