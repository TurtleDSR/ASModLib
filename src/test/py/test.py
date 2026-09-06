import lib.mod_lib as mod_lib;

context = mod_lib.init("scripts/")

if(not mod_lib.install_mod_asmod(context, "mods/test4.asmod")):
  print("[PY-DEBUG] FAILED INSTALLATION")
else:
  print("[PY-DEBUG] SUCCEEDED INSTALLATION")
  
mod_lib.destroy(context)