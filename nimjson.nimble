# Package

version       = "2.0.1"
author        = "jiro4989"
description   = "nimjson generates nim object definitions from json documents."
license       = "MIT"
srcDir        = "src"
bin           = @["nimjson"]
binDir        = "bin"
installExt    = @["nim"]

# Dependencies

requires "nim >= 0.20.0"

import std/strformat
import std/os

task docs, "Generate documents":
  exec "nimble doc --index:on --project src/nimjson.nim -o:docs"

task examples, "Run examples":
  for dir in ["readfile", "mapping"]:
    withDir "examples/" & dir:
      exec "nim c -d:release main.nim"
      exec "./main"

task buildjs, "Generate JS lib":
  mkdir "docs/js"
  exec "nimble js js/nimjson_js.nim -o:docs/js/nimjson.js"

task tests, "Run test":
  exec "testament p 'tests/test_*.nim'"
