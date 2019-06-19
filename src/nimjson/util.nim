import json, strformat, tables
from strutils import toUpperAscii, join, split

proc format2(self: JsonNode, objName: string, strs: var seq[string] = @[], index = 0)

proc headUpper(str: string): string =
  $(str[0].toUpperAscii() & str[1..^1])

proc getType(key: string, value: JsonNode, strs: var seq[string], index: int): string =
  case value.kind
  of JArray:
    let iObj = "Object" & $index
    var s = "seq["
    for child in value.elems:
      s.add(getType(iObj, child, strs, index))

      case child.kind
      of JObject:
        child.format2(iObj, strs, index+1)
      else: discard
      break
    s.add("]")
    s
  of JObject: key.headUpper()
  of JString: "string"
  of JInt: "int64"
  of JFloat: "float64"
  of JBool: "bool"
  of JNull: "JNull"

proc format2(self: JsonNode, objName: string, strs: var seq[string] = @[], index = 0) =
  ## self must be object.
  strs.add("")
  strs[index].add(&"  {objName.headUpper()} = ref object\n")
  for k, v in self.fields:
    let t = getType(k, v, strs, index)
    strs[index].add(&"    {k}: {t}\n")

    case v.kind
    of JObject:
      v.format2(k, strs, index+1)
    else: discard

proc format*(self: JsonNode, objName = "Object"): string =
  result.add(&"type\n")
  case self.kind
  of JObject:
    var ret: seq[string]
    self.format2(objName, ret)
    result.add(ret.join())
  else:
    discard

when isMainModule:
  echo """
    {
      "int":1,
      "str":"string",
      "float":1.24,
      "bool":true
    }""".parseJson().format()

  echo """{"str":"string1", "int":1, "float":1.15, "array":[1, 2, 3],
           "testObject":{"int":1, "obj2":{"str":"s", "bool2":true, "bool3":false},
           "str":"s", "float":1.12},
           "array":[null, 1, 2, 3],
           "objectArray":[{"int":1, "bool":true, "b":false}, {"int":2, "bool":false, "b":true}],
          }""".parseJson().format()
