import json, strformat, tables
from strutils import toUpperAscii, join

proc getType(key: string, value: JsonNode): string =
  case value.kind
  of JArray:
    var s = "seq["
    for child in value.elems:
      s.add(getType("Not use key", child))
      break
    s.add("]")
    s
  of JObject: $(key[0].toUpperAscii() & key[1..^1])
  of JString: "string"
  of JInt: "int64"
  of JFloat: "float64"
  of JBool: "bool"
  of JNull: "JNull"

proc format2*(self: JsonNode, objName = "Object", strs: var seq[string] = @[], index = 0) =
  ## self must be object.
  strs.add("")
  strs[index].add(&"  {objName} = ref object\n")
  for k, v in self.fields:
    let t = getType(k, v)
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
    self.format2("object", ret)
    result.add(ret.join())
  else:
    discard

proc toUgry*(result: var string, node: JsonNode) =
  ## Converts `node` to its JSON Representation, without
  ## regard for human readability. Meant to improve ``$`` string
  ## conversion performance.
  ##
  ## JSON representation is stored in the passed `result`
  ##
  ## This provides higher efficiency than the ``pretty`` procedure as it
  ## does **not** attempt to format the resulting JSON to make it human readable.
  var comma = false
  case node.kind:
  of JArray:
    result.add "["
    for child in node.elems:
      if comma: result.add ","
      else:     comma = true
      result.toUgly child
    result.add "]"
  of JObject:
    result.add "{"
    for key, value in pairs(node.fields):
      if comma: result.add ","
      else:     comma = true
      key.escapeJson(result)
      result.add ":"
      result.toUgly value
    result.add "}"
  of JString:
    node.str.escapeJson(result)
  of JInt:
    when defined(js): result.add($node.num)
    else: result.addInt(node.num)
  of JFloat:
    when defined(js): result.add($node.fnum)
    else: result.addFloat(node.fnum)
  of JBool:
    result.add(if node.bval: "true" else: "false")
  of JNull:
    result.add "null"

when isMainModule:
  echo """{"str":"string1", "int":1, "float":1.15, "array":[1, 2, 3], "testObject":{"int":1, "obj2":{"str":"s", "bool2":true, "bool3":false}, "str":"s", "float":1.12}}""".parseJson().format()
