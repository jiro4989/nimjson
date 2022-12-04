import nimjson

proc generateNimDefinitions(str: cstring, publicField: bool,
    jsonSchema: bool): cstring {.exportc.} =
  return str.`$`.toTypeString(publicField = publicField,
      jsonSchema = jsonSchema)
