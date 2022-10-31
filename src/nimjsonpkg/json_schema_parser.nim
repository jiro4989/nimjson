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
    items: JsonSchemaItem
    required: seq[string]
    properties: OrderedTable[string, Property]

  JsonSchemaItem = ref object
    `type`: string

func isTypeObject(prop: Property): bool =
  prop.`type` == "object"

func isTypeArray(prop: Property): bool =
  prop.`type` == "array"

func typeToNimTypeName(typ: string): string =
  case typ
  of "string": "string"
  of "integer": "int64"
  of "number": "float64"
  of "bool": "bool"
  of "null": "NilType"
  else: ""

func getPropertyType(prop: Property, propName: string): string =
  if prop.isTypeObject: propName.headUpper
  elif prop.isTypeArray: prop.items.`type`
  else: prop.`type`.typeToNimTypeName

proc setObjectDefinitions(defs: var seq[ObjectDefinition], property: Property,
    objectName: string, isPublic: bool, forceBackquote: bool,
        disableOption: bool) =
  var objDef = newObjectDefinition(objectName.headUpper, false, isPublic, forceBackquote)
  for propName, prop in property.properties:
    let isOption = (not disableOption) and propName notin property.required
    let typ = prop.getPropertyType(propName)
    let fDef = newFieldDefinition(propName, typ, isPublic, forceBackquote,
        prop.isTypeArray, isOption)
    objDef.addFieldDefinition(fDef)
    if prop.isTypeObject:
      let p = Property(
        description: prop.description,
        `type`: prop.`type`,
        required: prop.required,
        properties: prop.properties,
        )
      defs.setObjectDefinitions(p, typ, isPublic, forceBackquote, disableOption)
  defs.add(objDef)

proc parseAndGetString*(s: string, objectName: string, isPublic: bool,
    forceBackquote: bool, disableOption: bool): string =
  var resultDefs: seq[ObjectDefinition]
  let schema = s.fromJson(JsonSchema)
  let property = Property(
    description: schema.description,
    `type`: schema.`type`,
    required: schema.required,
    properties: schema.properties,
    )
  resultDefs.setObjectDefinitions(property, objectName, isPublic,
      forceBackquote, disableOption)

  result.add("type\n")
  result.add(resultDefs.toDefinitionString())
