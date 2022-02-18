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
    objectName: string, isPublic, forceBackquote: bool) =
  case jsonNode.kind
  of JObject:
    defs.add(newObjectDefinition(objectName, false))
    let defIndex = defs.len - 1
    for name, node in jsonNode.fields:
      case node.kind
      of JString, JInt, JFloat, JBool, JNull:
        let typ = node.kind.kind2str
        let fieldDef = newFieldDefinition(name, typ, isPublic, forceBackquote, false)
        defs[defIndex].addFieldDefinition(fieldDef)
      of JArray:
        if 0 < node.elems.len:
          let child = node.elems[0]
          case child.kind
          of JString, JInt, JFloat, JBool, JNull:
            let typ = child.kind.kind2str
            let fieldDef = newFieldDefinition(name, typ, isPublic,
                forceBackquote, true)
            defs[defIndex].addFieldDefinition(fieldDef)
          of JObject:
            discard
          of JArray:
            # TODO
            discard
        else:
          let typ = "NilType"
          let fieldDef = newFieldDefinition(name, typ, isPublic, forceBackquote, true)
          defs[defIndex].addFieldDefinition(fieldDef)
      of JObject:
        let typ = name.headUpper
        let fieldDef = newFieldDefinition(name, typ, isPublic, forceBackquote, false)
        defs[defIndex].addFieldDefinition(fieldDef)
        node.parse(defs, typ, isPublic, forceBackquote)
  of JArray:
    if 0 < jsonNode.elems.len:
      let child = jsonNode.elems[0]
      case child.kind
      of JObject:
        let objectName = "Seq" & objectName
        child.parse(defs, objectName, isPublic, forceBackquote)
      else:
        discard
    else:
      # TODO
      discard
  else: discard
