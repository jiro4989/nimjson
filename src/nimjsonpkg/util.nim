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

import std/json
import std/strformat
import std/tables
from std/strutils import toUpperAscii, join, split

const
  nilType* = "NilType"

proc objFormat(self: JsonNode, objName: string, strs: var seq[string] = @[],
    index = 0, publicStr = "", quoteField = false)

proc headUpper(str: string): string =
  ## 先頭の文字を大文字にして返す。
  ## 先頭の文字だけを大文字にするので、**別にUpperCamelCeseにするわけではない**。
  $(str[0].toUpperAscii() & str[1..^1])

proc getType(key: string, value: JsonNode, strs: var seq[string], index: int,
    publicStr: string, quoteField: bool): string =
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
      s.add(getType(uKey, child, strs, index, publicStr, quoteField))
      if child.kind == JObject:
        child.objFormat(uKey, strs, index+1, publicStr, quoteField)
    else:
      s.add(nilType)
    s.add("]")
    s
  of JObject: key.headUpper()
  of JString: "string"
  of JInt: "int64"
  of JFloat: "float64"
  of JBool: "bool"
  of JNull: nilType

func quote(key: string, force: bool): string =
  ## ``key`` に空白文字や特殊な文字が含まれていた時はバッククオートで囲って返却する。
  ## ``force`` が有効の時は常にクオートする。
  ##
  ## See:
  ## * https://datatracker.ietf.org/doc/html/rfc8259#section-7
  const needQuoteChars = [
    # 0x22.char, # quotation mark
      # 0x5c.char, # reverse solidus
      # 0x2f.char, # solidus
      # 0x62.char, # backspace
      # 0x66.char, # form feed
      # 0x6e.char, # line feed
      # 0x72.char, # carriage return
      # 0x74.char, # tab
      #0x75.char, # 4hexdig
    '\\',
    '/',
    ' ',
  ]
  const reservedKeyword = [
    "type",
    "object",
    "enum",
    "let",
    "const",
    "var",
  ]
  result = &"`{key}`"
  if force:
    return
  for ch in needQuoteChars:
    if ch in key:
      return
  for keyword in reservedKeyword:
    if key == keyword:
      return
  return key

proc objFormat(self: JsonNode, objName: string, strs: var seq[string] = @[],
    index = 0, publicStr = "", quoteField = false) =
  ## Object型のJsonNodeをObject定義の文字列に変換して`strs[index]`に追加する。
  ## このとき`type`は追加しない。
  strs.add("")
  strs[index].add(&"  {objName.headUpper()}{publicStr} = ref object\n")
  for k, v in self.fields:
    let t = getType(k, v, strs, index, publicStr, quoteField)
    strs[index].add(&"    {k.quote(quoteField)}{publicStr}: {t}\n")

    # Object型を処理したときは、Object型の定義が別途必要になるので追加
    if v.kind == JObject:
      v.objFormat(k, strs, index+1, publicStr, quoteField)

proc toTypeString*(self: JsonNode, objName = "Object",
    publicField = false, quoteField = false): string =
  ## Generates nim object definitions string from ``JsonNode``.
  ## Returns a public field string if ``publicField`` was true.
  ##
  ## **Japanese:**
  ##
  ## ``JsonNode`` をNimのObject定義の文字列に変換して返却する。
  ## ``objName`` が定義するObjectの名前になる。
  ## ``publicField`` を指定すると、公開フィールドとして文字列を返却する。
  ##
  ## **Note:**
  ## * 値が ``null`` あるいは配列の最初の要素が ``null`` や値が空配列の場合は、
  ##   型が `nilType <#nilType>`_ になる。
  runnableExamples:
    import json
    from strutils import split

    let typeStr = """{"keyStr":"str",
                      "keyInt":1,
                      "keyFloat":1.1,
                      "keyBool":true}""".parseJson().toTypeString()
    let typeLines = typeStr.split("\n")
    doAssert typeLines[0] == "type"
    doAssert typeLines[1] == "  " & nilType & " = ref object"
    doAssert typeLines[2] == "  Object = ref object"
    doAssert typeLines[3] == "    keyStr: string"
    doAssert typeLines[4] == "    keyInt: int64"
    doAssert typeLines[5] == "    keyFloat: float64"
    doAssert typeLines[6] == "    keyBool: bool"

  # フィールドを公開するときに指定する文字列
  let publicStr =
    if publicField: "*"
    else: ""

  result.add("type\n")
  result.add(&"  {nilType}{publicStr} = ref object\n")
  case self.kind
  of JObject:
    var ret: seq[string]
    self.objFormat(objName, ret, publicStr = publicStr, quoteField = quoteField)
    result.add(ret.join())
  of JArray:
    let seqObjName = &"Seq{objName.headUpper()}"
    if 0 < self.elems.len():
      let child = self.elems[0]
      case child.kind
      of JObject:
        result.add(&"  {seqObjName} = seq[{objName}]\n")
        var ret: seq[string]
        child.objFormat(objName, ret, publicStr = publicStr,
            quoteField = quoteField)
        result.add(ret.join())
      else:
        var strs: seq[string]
        let t = getType(objName, child, strs, 0, publicStr, quoteField)
        result.add(&"  {objName} = seq[{t}]\n")
  else: discard
