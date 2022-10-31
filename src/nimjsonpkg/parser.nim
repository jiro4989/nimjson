import std/json
import std/tables
import std/strutils

import ./types
import ./utils

func kind2str(kind: JsonNodeKind): string =
  case kind
  of JString: "string"
  of JInt: "int64"
  of JFloat: "float64"
  of JBool: "bool"
  of JNull: "NilType"
  else: ""

func originalOrNumberedTypeName(typeNamebuffer: var Table[string, bool],
    typeName: string): string =
  ## This procedure adds a number to suffix if type names are duplicated.
  if not typeNamebuffer.hasKey(typeName):
    typeNamebuffer[typeName] = true
    return typeName
  var i = 2
  result = typeName & $i
  while typeNamebuffer.hasKey(result):
    inc i
    result = typeName & $i
  typeNamebuffer[result] = true

proc parse(jsonNode: JsonNode, defs: var seq[ObjectDefinition],
    defIndex: int, objectName: string, isPublic, forceBackquote, isSeq: bool,
    typeNameBuffer: var Table[string, bool]) =
  ## Parse Json Node.
  ## This procedure adds a number to suffix if type names are duplicated.
  case jsonNode.kind
  of JObject:
    let defIndex = defs.len
    defs.add(newObjectDefinition(objectName.headUpper, false, isPublic,
        forceBackquote))
    for name, node in jsonNode.fields:
      var name = name
      case node.kind
      of JObject:
        let srcName = name
        name = originalOrNumberedTypeName(typeNameBuffer, name)
        let typ = name.headUpper
        let fieldDef = newFieldDefinition(srcName, typ, isPublic,
            forceBackquote, false)
        defs[defIndex].addFieldDefinition(fieldDef)
      of JArray:
        if 0 < node.elems.len and node.elems[0].kind == JObject:
          let srcName = name
          name = originalOrNumberedTypeName(typeNameBuffer, name)
          let typ = name.headUpper
          let fieldDef = newFieldDefinition(srcName, typ, isPublic,
              forceBackquote, true)
          defs[defIndex].addFieldDefinition(fieldDef)
      else: discard

      node.parse(defs, defIndex, name, isPublic, forceBackquote, false, typeNameBuffer)
  of JArray:
    if 0 < jsonNode.elems.len:
      let child = jsonNode.elems[0]
      child.parse(defs, defIndex, objectName, isPublic, forceBackquote, true, typeNameBuffer)
    else:
      let typ = "NilType"
      let fieldDef = newFieldDefinition(objectName, typ, isPublic,
          forceBackquote, true)
      defs[defIndex].addFieldDefinition(fieldDef)
  of JString, JInt, JFloat, JBool, JNull:
    let typ = jsonNode.kind.kind2str
    let fieldDef = newFieldDefinition(objectName, typ, isPublic, forceBackquote, isSeq)
    defs[defIndex].addFieldDefinition(fieldDef)

proc parse(jsonNode: JsonNode, defs: var seq[ObjectDefinition],
    defIndex: int, objectName: string, isPublic, forceBackquote, isSeq: bool) =
  ## Parse Json Node.
  ## This procedure adds a number to suffix if type names are duplicated.
  var typeNameBuffer = initTable[string, bool]()
  jsonNode.parse(defs, defIndex, objectName, isPublic, forceBackquote, isSeq, typeNameBuffer)

proc parseAndGetString*(jsonNode: JsonNode, objectName: string, isPublic,
    forceBackquote: bool): string =
  var defs: seq[ObjectDefinition]
  jsonNode.parse(defs, 0, objectName, isPublic = isPublic,
      forceBackquote = forceBackquote, isSeq = false)

  # NilTypeは必須
  var resultDefs: seq[ObjectDefinition]
  resultDefs.add(newNilTypeObjectDefinition(isPublic, forceBackquote))
  resultDefs.add(defs)

  result.add("type\n")
  result.add(resultDefs.toDefinitionString)
