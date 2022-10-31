import std/tables

import jsony

import ./types
import ./utils

type
  JsonSchema = object
    title: string
    description: string
    `type`: string
    required: seq[string]
    additionalProperties: bool
    properties: OrderedTable[string, Property]

  Property = ref object
    description: string
    `type`: string
    required: seq[string]
    properties: OrderedTable[string, Property]

func typeStr(typ: string): string =
  case typ
  of "string": "string"
  of "integer": "int64"
  of "number": "float64"
  of "bool": "bool"
  of "null": "NilType"
  else: ""

proc toObjectDefinitions(schema: JsonSchema, objectName: string, isPublic: bool,
    forceBackquote: bool, disableOption: bool): seq[ObjectDefinition] =
  var objDef = newObjectDefinition(objectName.headUpper, false, isPublic, forceBackquote)
  for propName, prop in schema.properties:
    let typ = prop.`type`
    let isOption = (not disableOption) and propName notin schema.required
    let fDef = newFieldDefinition(propName, typ.typeStr, isPublic,
        forceBackquote, false, isOption)
    objDef.addFieldDefinition(fDef)
  result.add(objDef)

proc parseAndGetString*(s: string, objectName: string, isPublic: bool,
    forceBackquote: bool, disableOption: bool): string =
  var resultDefs: seq[ObjectDefinition]
  let schema = s.fromJson(JsonSchema)
  resultDefs.add(schema.toObjectDefinitions(objectName, isPublic,
      forceBackquote, disableOption))

  result.add("type\n")
  result.add(resultDefs.toDefinitionString())
