import nimjson
import json

proc generateNimDefinitions(str: cstring, publicField: bool): cstring {.exportc.} =
  return str.`$`.parseJson().toTypeString(publicField = publicField)