import std/tables
from std/strformat import `&`

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

  JsonSchemaParser = object
    defs: seq[ObjectDefinition]
    isPublic: bool
    forceBackquote: bool
    disableOption: bool

func isTypeObject(prop: Property): bool =
  prop.`type` == "object"

func isTypeArray(prop: Property): bool =
  prop.`type` == "array"

func typeToNimTypeName(typ: string): string =
  ## https://json-schema.org/understanding-json-schema/reference/type.html
  case typ
  of "string": "string"
  of "integer": "int64"
  of "number": "float64"
  of "boolean": "bool"
  of "null": "NilType"
  else: raise newException(UnsupportedTypeError,
      &"{typ} is not supported type. type must be string, integer, number, boolean, or null.")

func getPropertyType(prop: Property, propName: string): string =
  if prop.isTypeObject: propName.headUpper
  elif prop.isTypeArray: prop.items.`type`
  else: prop.`type`.typeToNimTypeName

proc parse(parser: var JsonSchemaParser, property: Property, objectName: string) =
  var objDef = newObjectDefinition(objectName.headUpper, false, parser.isPublic, parser.forceBackquote)
  for propName, prop in property.properties:
    let isOption = (not parser.disableOption) and propName notin property.required
    let typ = prop.getPropertyType(propName)
    let fDef = newFieldDefinition(propName, typ, parser.isPublic, parser.forceBackquote,
        prop.isTypeArray, isOption)
    objDef.addFieldDefinition(fDef)
    if prop.isTypeObject:
      let p = Property(
        description: prop.description,
        `type`: prop.`type`,
        required: prop.required,
        properties: prop.properties,
        )
      parser.parse(p, typ)
  parser.defs.add(objDef)

proc parseAndGetString*(s: string, objectName: string, isPublic: bool,
    forceBackquote: bool, disableOption: bool): string =
  var parser = JsonSchemaParser(
    isPublic: isPublic,
    forceBackquote: forceBackquote,
    disableOption: disableOption,
  )
  let schema = s.fromJson(JsonSchema)
  let property = Property(
    description: schema.description,
    `type`: schema.`type`,
    required: schema.required,
    properties: schema.properties,
    )
  parser.parse(property, objectName)

  result.add("type\n")
  result.add(parser.defs.toDefinitionString())
