import std/json
import std/tables
import std/strutils

import ./types

#[

{
  "a":1,
  "b":{
    "b1":1,
    "b2":2
  },
  "c":3
}

type
  obj = ref object
    a: int
    b: B
    c: int
  B = ref object
    b1: int
    b2: int

]#

func headUpper(str: string): string =
  ## 先頭の文字を大文字にして返す。
  ## 先頭の文字だけを大文字にするので、**別にUpperCamelCeseにするわけではない**。
  $(str[0].toUpperAscii() & str[1..^1])

func kind2str(kind: JsonNodeKind): string =
  case kind
  of JString: "string"
  of JInt: "int64"
  of JFloat: "float64"
  of JBool: "bool"
  of JNull: "NilType"
  else: ""

proc parse*(jsonNode: JsonNode, defs: var seq[ObjectDefinition],
    defIndex: int, objectName: string, isPublic, forceBackquote, isSeq: bool) =
  case jsonNode.kind
  of JObject:
    let defIndex = defs.len
    defs.add(newObjectDefinition(objectName.headUpper, false))
    for name, node in jsonNode.fields:
      case node.kind
      of JObject:
        let typ = name.headUpper
        let fieldDef = newFieldDefinition(name, typ, isPublic, forceBackquote, false)
        defs[defIndex].addFieldDefinition(fieldDef)
      of JArray:
        if 0 < node.elems.len and node.elems[0].kind == JObject:
          let typ = name.headUpper
          let fieldDef = newFieldDefinition(name, typ, isPublic, forceBackquote, true)
          defs[defIndex].addFieldDefinition(fieldDef)
      else: discard

      node.parse(defs, defIndex, name, isPublic, forceBackquote, false)
  of JArray:
    if 0 < jsonNode.elems.len:
      let child = jsonNode.elems[0]
      child.parse(defs, defIndex, objectName, isPublic, forceBackquote, true)
    else:
      let typ = "NilType"
      let fieldDef = newFieldDefinition(objectName, typ, isPublic,
          forceBackquote, true)
      defs[defIndex].addFieldDefinition(fieldDef)
  of JString, JInt, JFloat, JBool, JNull:
    let typ = jsonNode.kind.kind2str
    let fieldDef = newFieldDefinition(objectName, typ, isPublic, forceBackquote, isSeq)
    defs[defIndex].addFieldDefinition(fieldDef)
