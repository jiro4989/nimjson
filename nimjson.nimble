# Package

version       = "0.1.0"
author        = "jiro4989"
description   = "Command to convert JSON string to Nim types."
license       = "MIT"
srcDir        = "src"
bin           = @["nimjson"]
binDir        = "bin"


# Dependencies

requires "nim >= 0.20.0"

task docs, "Generate documents":
  exec "nimble doc src/nimjson.nim -o:docs/nimjson.html"

task examples, "Run examples":
  withDir "examples/readfile":
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
