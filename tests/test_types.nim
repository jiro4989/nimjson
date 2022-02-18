discard """
  exitCode: 0
  output: ""
"""

import std/unittest

include nimjsonpkg/types

block:
  checkpoint "func toDefinitionStringLines"

  block:
    checkpoint "正常系: プリミティブなフィールドのみ"

    var obj = newObjectDefinition("Object", false, true)
    obj.addFieldDefinition(newFieldDefinition("a", "int64", true, false, false))
    obj.addFieldDefinition(newFieldDefinition("b", "bool", true, false, false))
    obj.addFieldDefinition(newFieldDefinition("c", "float64", true, false, false))
    obj.addFieldDefinition(newFieldDefinition("d", "NilType", true, false, false))
    obj.addFieldDefinition(newFieldDefinition("e", "string", true, false, false))
    let got = obj.toDefinitionStringLines
    check got.len == 6
    check got[0] == "  Object* = ref object"
    check got[1] == "    a*: int64"
    check got[2] == "    b*: bool"
    check got[3] == "    c*: float64"
    check got[4] == "    d*: NilType"
    check got[5] == "    e*: string"

  block:
    checkpoint "正常系: 特殊な文字が含まれる場合は無効化する"

    var obj = newObjectDefinition("Object", false, false)
    obj.addFieldDefinition(newFieldDefinition("hello world", "int64", false,
        false, false))
    obj.addFieldDefinition(newFieldDefinition("su, shi", "bool", false, false, false))
    obj.addFieldDefinition(newFieldDefinition("abc*", "float64", false, false, false))
    obj.addFieldDefinition(newFieldDefinition("a", "string", false, false, false))
    obj.addFieldDefinition(newFieldDefinition("type", "string", false, false, false))
    let got = obj.toDefinitionStringLines
    check got.len == 6
    check got[0] == "  Object = ref object"
    check got[1] == "    `hello world`: int64"
    check got[2] == "    `su shi`: bool"
    check got[3] == "    `abc*`: float64"
    check got[4] == "    a: string"
    check got[5] == "    `type`: string"

  block:
    checkpoint "正常系: NilType"

    var obj = newObjectDefinition("Object", true, true)
    let got = obj.toDefinitionStringLines
    check got.len == 1
    check got[0] == "  NilType* = ref object"

block:
  checkpoint "func toDefinitionString"

  block:
    checkpoint "正常系: プリミティブなフィールドのみ"

    var obj1 = newObjectDefinition("Object", false, true)
    obj1.addFieldDefinition(newFieldDefinition("sushi", "Sushi", true, false, false))

    var obj2 = newObjectDefinition("Sushi", false, true)
    obj2.addFieldDefinition(newFieldDefinition("name", "string", true, false, false))

    let got = @[obj1, obj2].toDefinitionString

    check got == """
  Object* = ref object
    sushi*: Sushi
  Sushi* = ref object
    name*: string"""
