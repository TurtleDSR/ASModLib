flags := "-std=c23 -O3"

[group: "lib"]
[windows]
lib: bind build-libs

[group: "lib"]
[windows]
build-libs:
  @#C
  clang {{flags}} -DDLLBUILD -c src/lib/mod_install.c include/zip.c -Iinclude/headers/

  @[ -d .build/tmp/c/ ] || mkdir -p .build/tmp/c/
  mv *.o .build/tmp/c/

  @[ -d .build/lib/c/ ] || mkdir -p .build/lib/c/
  clang -shared -o .build/lib/c/mod_install.dll .build/tmp/c/*.o

  rm .build/lib/c/mod_install.exp

  cp src/lib/mod_install.h .build/lib/c/
  cp include/headers/zip.h .build/lib/c/
  cp include/headers/miniz.h .build/lib/c/

  @#Java
  clang {{flags}} -DDLLBUILD -c src/lib/mod_install.c .build/wrap/java/mod_install_wrap.c include/zip.c -Iinclude/wrapper_lib/jni -Iinclude/headers/ -Isrc/lib/

  @[ -d .build/tmp/java/ ] || mkdir -p .build/tmp/java/
  mv *.o .build/tmp/java/

  @[ -d .build/lib/java/ ] || mkdir -p .build/lib/java/
  clang -shared -o .build/lib/java/mod_install.dll .build/tmp/java/*.o

  rm .build/lib/java/mod_install.exp
  rm .build/lib/java/mod_install.lib

  cp .build/wrap/java/mod_install.java .build/lib/java/
  cp .build/wrap/java/mod_installJNI.java .build/lib/java/

  @#Python
  clang {{flags}} -DDLLBUILD -c src/lib/mod_install.c .build/wrap/python/mod_install_wrap.c include/zip.c -Iinclude/wrapper_lib/python/headers/ -Iinclude/headers/ -Isrc/lib/

  @[ -d .build/tmp/python/ ] || mkdir -p .build/tmp/python/
  mv *.o .build/tmp/python/

  @[ -d .build/lib/python/ ] || mkdir -p .build/lib/python/
  clang -shared -o .build/lib/python/_mod_install.pyd .build/tmp/python/*.o -Linclude/wrapper_lib/python/libs/ -lpython314

  rm .build/lib/python/_mod_install.exp
  rm .build/lib/python/_mod_install.lib

  cp .build/wrap/python/mod_install.py .build/lib/python/

  @#csharp
  clang {{flags}} -DDLLBUILD -c src/lib/mod_install.c .build/wrap/csharp/mod_install_wrap.c include/zip.c -Iinclude/headers/ -Isrc/lib/

  @[ -d .build/tmp/csharp/ ] || mkdir -p .build/tmp/csharp/
  mv *.o .build/tmp/csharp/

  @[ -d .build/lib/csharp/ ] || mkdir -p .build/lib/csharp/
  clang -shared -o .build/lib/csharp/mod_install.dll .build/tmp/csharp/*.o

  rm .build/lib/csharp/mod_install.exp
  rm .build/lib/csharp/mod_install.lib

  cp .build/wrap/csharp/mod_install.cs .build/lib/csharp/
  cp .build/wrap/csharp/mod_installPINVOKE.cs .build/lib/csharp/

[group: "lib"]
[windows]
bind:
  @#make missing directories 
  @[ -d .build/wrap/python/ ] || mkdir -p .build/wrap/python/
  @[ -d .build/wrap/java/ ] || mkdir -p .build/wrap/java/
  @[ -d .build/wrap/csharp/ ] || mkdir -p .build/wrap/csharp/

  @#generate bindings
  swig -python -py3 -outdir .build/wrap/python -o .build/wrap/python/mod_install_wrap.c src/lib/mod_install.i
  swig -java -outdir .build/wrap/java -o .build/wrap/java/mod_install_wrap.c src/lib/mod_install.i
  swig -csharp -outdir .build/wrap/csharp -o .build/wrap/csharp/mod_install_wrap.c src/lib/mod_install.i

[group: "executable"]
[windows]
build: lib
  @[ -d .build/executable/ ] || mkdir -p .build/executable/
  @[ -d .build/tmp/exe/ ] || mkdir -p .build/tmp/exe/

  cp .build/lib/c/mod_install.h src/executable/
  cp .build/lib/c/zip.h src/executable/
  cp .build/lib/c/miniz.h src/executable/

  cp .build/lib/c/mod_install.dll .build/executable/

  clang {{flags}} -c src/executable/main.c -o .build/executable/mod_install.exe -Isrc/executable/
