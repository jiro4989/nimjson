import nimjson
import json

proc generateNimDefinitions(str: cstring): cstring {.exportc.} =
  return str.`$`.parseJson().toTypeString()