# Package

version       = "1.2.5"
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

task format, "Format codes":
  for f in listFiles("src"):
    exec &"nimpretty {f}"
  for f in listFiles("src" / "nimjsonpkg"):
    exec &"nimpretty {f}"

task checkFormat, "Checking that codes were formatted":
  var errCount = 0
  for f in listFiles("src"):
    let tmpFile = f & ".tmp"
    exec &"nimpretty --output:{tmpFile} {f}"
    if readFile(f) != readFile(tmpFile):
      inc errCount
    rmFile tmpFile
  for f in listFiles("src" / "nimjsonpkg"):
    let tmpFile = f & ".tmp"
    exec &"nimpretty --output:{tmpFile} {f}"
    if readFile(f) != readFile(tmpFile):
      inc errCount
    rmFile tmpFile
  exec &"exit {errCount}"

task ci, "Run CI":
  exec "nim -v"
  exec "nimble -v"
  exec "nimble check"
  if buildOS == "linux":
    exec "nimble checkFormat"
  exec "nimble install -Y"
  exec "nimble test -Y"
  exec "nimble docs -Y"
  exec "nimble build -d:release -Y"
  exec "nimble examples"
  exec "nimble buildjs"
  exec "./bin/nimjson -h"
  exec "./bin/nimjson -v"

task archive, "Create archived assets":
  let app = "nimjson"
  let assets = &"{app}_{buildOS}"
  let dir = "dist"/assets
  mkDir dir
  cpDir "bin", dir/"bin"
  cpFile "LICENSE", dir/"LICENSE"
  cpFile "README.md", dir/"README.md"
  withDir "dist":
    when buildOS == "windows":
      exec &"7z a {assets}.zip {assets}"
    else:
      exec &"tar czf {assets}.tar.gz {assets}"
