## nimjson is the module to generate nim object definitions from json documents.
##
## nimjsonはJSON文字列をNimのObject定義の文字列に変換するためのモジュールです。
##
## Usage / 使い方
## --------------
##
## .. code-block:: nim
##    import nimjson
##    import json
##    
##    echo """{"keyStr":"str", "keyInt":1}""".parseJson().toTypeString()
##
##    # Output:
##    # type
##    #   Object = ref object
##    #     keyStr: string
##    #     keyInt: int64
##
##    echo "examples/primitive.json".parseFile().toTypeString("testObject")

import json, strformat, tables
from strutils import toUpperAscii, join, split

proc objFormat(self: JsonNode, objName: string, strs: var seq[string] = @[], index = 0)

proc headUpper(str: string): string =
  ## 先頭の文字を大文字にして返す。
  ## 先頭の文字だけを大文字にするので、**別にUpperCamelCeseにするわけではない**。
  $(str[0].toUpperAscii() & str[1..^1])

proc getType(key: string, value: JsonNode, strs: var seq[string], index: int): string =
  ## `value`の型文字列を返す。
  ## Object型や配列内の要素がObject型の場合は、`key`の文字列の先頭を大文字にした
  ## ものを型名として返す。
  ## 型がObject型だった場合は ``strs`` にObject型定義を追加する。
  case value.kind
  of JArray:
    let uKey = key.headUpper()
    var s = "seq["
    if 0 < value.elems.len():
      # 配列の最初の要素の方を取得
      let child = value.elems[0]
      s.add(getType(uKey, child, strs, index))
      if child.kind == JObject:
        child.objFormat(uKey, strs, index+1)
    else:
      s.add("JNull")
    s.add("]")
    s
  of JObject: key.headUpper()
  of JString: "string"
  of JInt: "int64"
  of JFloat: "float64"
  of JBool: "bool"
  of JNull: "JNull"

proc objFormat(self: JsonNode, objName: string, strs: var seq[string] = @[], index = 0) =
  ## Object型のJsonNodeをObject定義の文字列に変換して`strs[index]`に追加する。
  ## このとき`type`は追加しない。
  strs.add("")
  strs[index].add(&"  {objName.headUpper()} = ref object\n")
  for k, v in self.fields:
    let t = getType(k, v, strs, index)
    strs[index].add(&"    {k}: {t}\n")

    # Object型を処理したときは、Object型の定義が別途必要になるので追加
    if v.kind == JObject:
      v.objFormat(k, strs, index+1)

proc toTypeString*(self: JsonNode, objName = "Object"): string =
  ## Generates nim object definitions string from ``JsonNode``.
  ##
  ## **Japanese:**
  ##
  ## ``JsonNode`` をNimのObject定義の文字列に変換して返却する。
  ## ``objName`` が定義するObjectの名前になる。
  ##
  ## **Note:**
  ## * 値が ``null`` あるいは配列の最初の要素が ``null`` や値が空配列の場合は、
  ##   型が ``JNull`` になる。
  runnableExamples:
    import json
    from strutils import split

    let typeStr = """{"keyStr":"str",
                      "keyInt":1,
                      "keyFloat":1.1,
                      "keyBool":true}""".parseJson().toTypeString()
    let typeLines = typeStr.split("\n")
    doAssert typeLines[0] == "type"
    doAssert typeLines[1] == "  Object = ref object"
    doAssert typeLines[2] == "    keyStr: string"
    doAssert typeLines[3] == "    keyInt: int64"
    doAssert typeLines[4] == "    keyFloat: float64"
    doAssert typeLines[5] == "    keyBool: bool"

  result.add("type\n")
  case self.kind
  of JObject:
    var ret: seq[string]
    self.objFormat(objName, ret)
    result.add(ret.join())
  of JArray:
    let seqObjName = &"Seq{objName.headUpper()}"
    if 0 < self.elems.len():
      let child = self.elems[0]
      case child.kind
      of JObject:
        result.add(&"  {seqObjName} = seq[{objName}]\n")
        var ret: seq[string]
        child.objFormat(objName, ret)
        result.add(ret.join())
      else:
        var strs: seq[string]
        let t = getType(objName, child, strs, 0)
        result.add(&"  {objName} = seq[{t}]\n")
  else: discard