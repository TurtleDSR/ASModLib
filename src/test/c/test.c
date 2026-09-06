#include "mod_lib.h"

#include <stdio.h>

int main(int argc, char** argv) {
  mod_lib_context* context = mod_lib_init("scripts/");

  if(!install_mod_asmod(context, "mods/test1.asmod")) {
    puts("[C-DEBUG] FAILED INSTALLATION");
  } else {
    puts("[C-DEBUG] SUCCEEDED INSTALLATION");
  }

  mod_lib_destroy(context);
  return 0;
}