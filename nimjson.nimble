# Package

version       = "1.2.6"
author        = "jiro4989"
description   = "nimjson generates nim object definitions from json documents."
license       = "MIT"
srcDir        = "src"
bin           = @["nimjson"]
binDir        = "bin"
installExt    = @["nim"]

# Dependencies

requires "nim >= 0.20.0"
import strformat, os

task docs, "Generate documents":
  exec "nimble doc src/nimjson.nim -o:docs/nimjson.html"

task examples, "Run examples":
  for dir in ["readfile", "mapping"]:
    withDir "examples/" & dir:
      exec "nim c -d:release main.nim"
      exec "./main"

task buildjs, "Generate JS lib":
  mkdir "docs/js"
  exec "nimble js js/nimjson_js.nim -o:docs/js/nimjson.js"
