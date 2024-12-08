import std/tables
import std/strutils
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
    `definitions`: OrderedTable[string, Property]
    `$defs`: OrderedTable[string, Property] # same as `definitions`

  Property = ref object
    description: string
    `type`: string
    items: JsonSchemaItem
    required: seq[string]
    properties: OrderedTable[string, Property]
    `$ref`: string

  JsonSchemaItem = ref object
    `type`: string

  JsonSchemaParser = object
    defs: seq[ObjectDefinition]
    isPublic: bool
    forceBackquote: bool
    disableOptionType: bool

func isValidJsonPointer(s: string): bool =
  # if it is syntatically valid, not if it evaluates
  var offset = 0
  if s.startsWith('#'):
    offset = 1
  if s[offset..^1] == "":
    return true
  if not s[offset..^1].startsWith("/"):
    return false
  let components = s[offset..^1].split('/')[1..^1]
  for c in components:
    var i = 0
    while i < c.len:
      if c[i] == '~':
        if i+1 >= c.len or not(c[i+1] in "01"):
          return false
        inc i
      inc i
  return true

func validateRef(prop: Property) =
  # A ref may be URI, URI reference, URI template, or JSON pointer
  let s = prop.`$ref`
  # Only supports pointer (RFC6901)
  if isValidJsonPointer(s):
    return
  raise newException(UnsupportedRefError,
      &"nimjson supports only JSON Pointer ref, e.g: '#/$defs/<name>'. $ref = {s}")

func newProperty(description: string, typ: string, required: seq[string],
    properties: OrderedTable[string, Property], re: string): Property =
  result = Property(
    description: description,
    `type`: typ,
    required: required,
    properties: properties,
    `$ref`: re,
  )
  result.validateRef()

func isTypeObject(prop: Property): bool =
  prop.`type` == "object"

func isTypeArray(prop: Property): bool =
  prop.`type` == "array"

func hasRef(prop: Property): bool =
  prop.`$ref` != ""

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

func getRefTypeName(prop: Property, propName: string): string =
  prop.validateRef()
  var s = prop.`$ref`
  if s.startsWith('#'):
    s = s[1..^1]
  result =
    if s == "": propName.headUpper
    elif s.startsWith("/definitions/"): s[13..^1]
    elif s.startsWith("/$defs/"): s[7..^1]
    else: s[1..^1]
  result = result.headUpper()

proc parse(parser: var JsonSchemaParser, property: Property,
    objectName: string) =
  if not property.isTypeObject:
    let typ =
      if property.isTypeArray: property.items.`type`
      else: property.`type`
    let objDef = newObjectDefinition(objectName.headUpper, false,
        parser.isPublic, parser.forceBackquote, typ, property.isTypeArray)
    parser.defs.add(objDef)
    return

  var objDef = newObjectDefinition(objectName.headUpper, false, parser.isPublic,
      parser.forceBackquote)
  for propName, prop in property.properties:
    let isOption = (not parser.disableOptionType) and propName notin
        property.required
    let typ =
      if prop.hasRef: prop.getRefTypeName(propName)
      else: prop.getPropertyType(propName)
    let fDef = newFieldDefinition(propName, typ, parser.isPublic,
        parser.forceBackquote, prop.isTypeArray, isOption)
    objDef.addFieldDefinition(fDef)
    if prop.isTypeObject:
      let p = newProperty(
        prop.description,
        prop.`type`,
        prop.required,
        prop.properties,
        prop.`$ref`,
      )
      parser.parse(p, typ)
  parser.defs.add(objDef)

proc parseAndGetString*(s: string, objectName: string, isPublic: bool,
    forceBackquote: bool, disableOptionType: bool): string =
  var parser = JsonSchemaParser(
    isPublic: isPublic,
    forceBackquote: forceBackquote,
    disableOptionType: disableOptionType,
  )

  let schema = s.fromJson(JsonSchema)
  let property = newProperty(
    schema.description,
    schema.`type`,
    schema.required,
    schema.properties,
    "",
  )
  parser.parse(property, objectName)

  for propName, prop in schema.`$defs`:
    parser.parse(prop, propName)
  for propName, prop in schema.`definitions`:
    parser.parse(prop, propName)

  result.add("type\n")
  result.add(parser.defs.toDefinitionString())
