import json, strformat, tables
from strutils import toUpperAscii, join, split

proc objFormat(self: JsonNode, objName: string, strs: var seq[string] = @[], index = 0)

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
        child.objFormat(iObj, strs, index+1)
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

proc objFormat(self: JsonNode, objName: string, strs: var seq[string] = @[], index = 0) =
  ## self must be object.
  strs.add("")
  strs[index].add(&"  {objName.headUpper()} = ref object\n")
  for k, v in self.fields:
    let t = getType(k, v, strs, index)
    strs[index].add(&"    {k}: {t}\n")

    case v.kind
    of JObject:
      v.objFormat(k, strs, index+1)
    else: discard

proc toTypeString*(self: JsonNode, objName = "Object"): string =
  result.add(&"type\n")
  case self.kind
  of JObject:
    var ret: seq[string]
    self.objFormat(objName, ret)
    result.add(ret.join())
  else: discard