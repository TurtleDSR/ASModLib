flags := `cat .flags 2>/dev/null || echo "-std=c23 -O3"`

[group: "lib"]
[windows]
lib:
  @echo "-std=c23 -O3" > .flags
  @just bind 
  @just build-libs

[group: "lib"]
[windows]
[parallel]
build-libs: build_lib_c build_lib_java build_lib_python build_lib_csharp

[group: "lib"]
[windows]
lib-test:
  @echo "-std=c23 -O0 -Dmod_lib_debug" > .flags
  @just bind 
  @just build-libs

build_lib_c:
  @#C
  @[ -d .build/tmp/c/ ] || mkdir -p .build/tmp/c/

  clang {{flags}} -DDLLBUILD -c src/lib/mod_lib.c -Iinclude/headers/ -o .build/tmp/c/mod_lib.o
  clang {{flags}} -DDLLBUILD -c include/zip.c -Iinclude/headers/ -o .build/tmp/c/zip.o

  @[ -d .build/lib/c/ ] || mkdir -p .build/lib/c/
  clang -shared -o .build/lib/c/mod_lib.dll .build/tmp/c/*.o

  rm .build/lib/c/mod_lib.exp

  cp src/lib/mod_lib.h .build/lib/c/

build_lib_java:
  @#Java
  @[ -d .build/tmp/java/ ] || mkdir -p .build/tmp/java/

  clang {{flags}} -DDLLBUILD -c src/lib/mod_lib.c -Iinclude/wrapper_lib/jni -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/java/mod_lib.o
  clang {{flags}} -DDLLBUILD -c .build/wrap/java/mod_lib_wrap.c -Iinclude/wrapper_lib/jni -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/java/mod_lib_wrap.o
  clang {{flags}} -DDLLBUILD -c include/zip.c -Iinclude/wrapper_lib/jni -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/java/zip.o

  @[ -d .build/lib/java/ ] || mkdir -p .build/lib/java/
  clang -shared -o .build/lib/java/mod_lib.dll .build/tmp/java/*.o

  rm .build/lib/java/mod_lib.exp
  rm .build/lib/java/mod_lib.lib

  javac --release 11 -d .build/tmp/java/jar .build/wrap/java/com/turtledsr/mod_lib/*.java
  jar -cvf .build/lib/java/mod_lib.jar -C .build/tmp/java/jar .

build_lib_python:
  @#Python
  @[ -d .build/tmp/python/ ] || mkdir -p .build/tmp/python/

  clang {{flags}} -DDLLBUILD -c src/lib/mod_lib.c -Iinclude/wrapper_lib/python/headers/ -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/python/mod_lib.o
  clang {{flags}} -DDLLBUILD -c .build/wrap/python/mod_lib_wrap.c -Iinclude/wrapper_lib/python/headers/ -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/python/mod_lib_wrap.o
  clang {{flags}} -DDLLBUILD -c include/zip.c -Iinclude/wrapper_lib/python/headers/ -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/python/zip.o

  @[ -d .build/lib/python/ ] || mkdir -p .build/lib/python/
  clang -shared -o .build/lib/python/_mod_lib.pyd .build/tmp/python/*.o -Linclude/wrapper_lib/python/libs/ -lpython314

  rm .build/lib/python/_mod_lib.exp
  rm .build/lib/python/_mod_lib.lib

  cp .build/wrap/python/mod_lib.py .build/lib/python/

build_lib_csharp:
  @#csharp
  @[ -d .build/tmp/csharp/ ] || mkdir -p .build/tmp/csharp/

  clang {{flags}} -DDLLBUILD -c src/lib/mod_lib.c -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/csharp/mod_lib.o
  clang {{flags}} -DDLLBUILD -c .build/wrap/csharp/mod_lib_wrap.c -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/csharp/mod_lib_wrap.o
  clang {{flags}} -DDLLBUILD -c include/zip.c -Iinclude/headers/ -Isrc/lib/ -o .build/tmp/csharp/zip.o

  @[ -d .build/lib/csharp/ ] || mkdir -p .build/lib/csharp/
  clang -shared -o .build/lib/csharp/mod_lib.dll .build/tmp/csharp/*.o

  rm .build/lib/csharp/mod_lib.exp
  rm .build/lib/csharp/mod_lib.lib

  dotnet new classlib -o .build/tmp/csharp/csharp_mod_lib --name csharp_mod_lib --force
  rm .build/tmp/csharp/csharp_mod_lib/Class1.cs
  cp -r .build/wrap/csharp/*.cs .build/tmp/csharp/csharp_mod_lib/
  dotnet build .build/tmp/csharp/csharp_mod_lib/csharp_mod_lib.csproj -c Release

  cp .build/tmp/csharp/csharp_mod_lib/bin/Release/net9.0/csharp_mod_lib.dll .build/lib/csharp/

[group: "lib"]
[windows]
bind:
  @#make missing directories 
  @[ -d .build/wrap/python/ ] || mkdir -p .build/wrap/python/
  @[ -d .build/wrap/java/com/turtledsr/mod_lib/ ] || mkdir -p .build/wrap/java/com/turtledsr/mod_lib/
  @[ -d .build/wrap/csharp/ ] || mkdir -p .build/wrap/csharp/

  @#generate bindings
  swig -python -outdir .build/wrap/python -o .build/wrap/python/mod_lib_wrap.c src/lib/mod_lib.i
  swig -java -package com.turtledsr.mod_lib -outdir .build/wrap/java/com/turtledsr/mod_lib -o .build/wrap/java/mod_lib_wrap.c src/lib/mod_lib.i
  swig -csharp -namespace com.turtledsr.mod_lib -outdir .build/wrap/csharp -o .build/wrap/csharp/mod_lib_wrap.c src/lib/mod_lib.i

[group: "test"]
[windows]
test-c: lib-test
  @[ -d .build/test/c/ ] || mkdir -p .build/test/c/
  @[ -d .build/tmp/test/c/ ] || mkdir -p .build/tmp/test/c/
  @[ -d .test/c/ ] || mkdir -p .test/c/

  cp .build/lib/c/mod_lib.h src/test/c/include/header/
  cp .build/lib/c/mod_lib.lib src/test/c/include/lib/

  cp .build/lib/c/mod_lib.dll .build/test/c/

  cp -r src/test/static/* .test/c/

  clang {{flags}} src/test/c/test.c -o .build/test/c/test.exe -Isrc/test/c/include/header -Lsrc/test/c/include/lib -lmod_lib -fsanitize=address

  cp .build/test/c/mod_lib.dll .test/c/
  cp .build/test/c/test.exe .test/c/

  cd .test/c/ && ./test.exe

[group: "test"]
[windows]
test-py: lib-test
  @[ -d .test/py/ ] || mkdir -p .test/py/

  cp .build/lib/python/_mod_lib.pyd src/test/py/lib/
  cp .build/lib/python/mod_lib.py src/test/py/lib/

  cp -r src/test/py/* .test/py/
  cp -r src/test/static/* .test/py/

  cd .test/py/ && py test.py

[group: "debug"]
[windows]
lint:
  clear
  clang-tidy src/lib/mod_lib.c -- -Iinclude/headers/ -DDLLBUILD -Dmod_lib_debug