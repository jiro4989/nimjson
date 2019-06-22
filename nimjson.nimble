# Package

version       = "1.0.2"
author        = "jiro4989"
description   = "nimjson generates nim object definitions from json documents."
license       = "MIT"
srcDir        = "src"
bin           = @["nimjson"]
binDir        = "bin"
installExt    = @["nim"]

# Dependencies

requires "nim >= 0.20.0"

task docs, "Generate documents":
  exec "nimble doc src/nimjson.nim -o:docs/nimjson.html"

task examples, "Run examples":
  for dir in ["readfile", "mapping"]:
    withDir "examples/" & dir:
      exec "nim c -d:release main.nim"
      exec "./main"

task buildjs, "Generate JS lib":
  exec "nimble js src/nimjson_js.nim -o:docs/js/nimjson.js"

task ci, "Run CI":
  exec "nim -v"
  exec "nimble -v"
  exec "nimble install -Y"
  exec "nimble test -Y"
  exec "nimble docs -Y"
  exec "nimble build -d:release -Y"
  exec "nimble examples"
  exec "nimble buildjs"
  exec "./bin/nimjson -h"
  exec "./bin/nimjson -v"
