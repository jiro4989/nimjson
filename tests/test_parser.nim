discard """
  exitCode: 0
  output: ""
"""

import std/unittest
import std/json

import nimjsonpkg/parser
import nimjsonpkg/types

block:
  checkpoint "正常系: プリミティブなフィールドのみ"
  let j = """{"a":1, "b":true, "c":3.14, "d":null, "e":"hello"}""".parseJson
  var defs: seq[ObjectDefinition]
  j.parse(defs, 0, "Object", false, false, false)

  var want = newObjectDefinition("Object", false)
  want.addFieldDefinition(newFieldDefinition("a", "int64", false, false, false))
  want.addFieldDefinition(newFieldDefinition("b", "bool", false, false, false))
  want.addFieldDefinition(newFieldDefinition("c", "float64", false, false, false))
  want.addFieldDefinition(newFieldDefinition("d", "NilType", false, false, false))
  want.addFieldDefinition(newFieldDefinition("e", "string", false, false, false))
  check defs == @[want]

block:
  checkpoint "正常系: ネストしたオブジェクト"
  let j = """
{
  "a": 1,
  "b": {
    "a": true,
    "b": 1
  },
  "c": 3.14
}
""".parseJson
  var defs: seq[ObjectDefinition]
  j.parse(defs, 0, "Object", false, false, false)

  var want1 = newObjectDefinition("Object", false)
  want1.addFieldDefinition(newFieldDefinition("a", "int64", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("b", "B", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("c", "float64", false, false, false))

  var want2 = newObjectDefinition("B", false)
  want2.addFieldDefinition(newFieldDefinition("a", "bool", false, false, false))
  want2.addFieldDefinition(newFieldDefinition("b", "int64", false, false, false))

  check defs == @[want1, want2]

block:
  checkpoint "正常系: ネストしたオブジェクトが複数"
  let j = """
{
  "test": {
    "a": 3.14
  },
  "b": {
    "a": true,
    "b": 1
  },
  "c": {
    "a": "sushi",
    "b": null
  }
}
""".parseJson
  var defs: seq[ObjectDefinition]
  j.parse(defs, 0, "Object", false, false, false)

  var want1 = newObjectDefinition("Object", false)
  want1.addFieldDefinition(newFieldDefinition("test", "Test", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("b", "B", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("c", "C", false, false, false))

  var want2 = newObjectDefinition("Test", false)
  want2.addFieldDefinition(newFieldDefinition("a", "float64", false, false, false))

  var want3 = newObjectDefinition("B", false)
  want3.addFieldDefinition(newFieldDefinition("a", "bool", false, false, false))
  want3.addFieldDefinition(newFieldDefinition("b", "int64", false, false, false))

  var want4 = newObjectDefinition("C", false)
  want4.addFieldDefinition(newFieldDefinition("a", "string", false, false, false))
  want4.addFieldDefinition(newFieldDefinition("b", "NilType", false, false, false))

  check defs == @[want1, want2, want3, want4]

block:
  checkpoint "正常系: 多段ネスト"
  let j = """
{
  "obj1": {
    "obj11": {
      "a": 1
    }
  },
  "obj2": {
    "b": 3.14
  },
}
""".parseJson
  var defs: seq[ObjectDefinition]
  j.parse(defs, 0, "Object", false, false, false)

  var want1 = newObjectDefinition("Object", false)
  want1.addFieldDefinition(newFieldDefinition("obj1", "Obj1", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("obj2", "Obj2", false, false, false))

  var want2 = newObjectDefinition("Obj1", false)
  want2.addFieldDefinition(newFieldDefinition("obj11", "Obj11", false, false, false))

  var want3 = newObjectDefinition("Obj11", false)
  want3.addFieldDefinition(newFieldDefinition("a", "int64", false, false, false))

  var want4 = newObjectDefinition("Obj2", false)
  want4.addFieldDefinition(newFieldDefinition("b", "float64", false, false, false))

  check defs == @[want1, want2, want3, want4]

block:
  checkpoint "正常系: オブジェクトの配列"
  let j = """
[
  {
    "obj1": {
      "obj11": {
        "a": 1
      }
    },
    "obj2": {
      "b": 3.14
    },
  },
  {
    "obj1": {
      "obj11": {
        "a": 2
      }
    },
    "obj2": {
      "b": 4.14
    },
  }
]
""".parseJson
  var defs: seq[ObjectDefinition]
  j.parse(defs, 0, "Object", false, false, false)

  var want1 = newObjectDefinition("Object", false)
  want1.addFieldDefinition(newFieldDefinition("obj1", "Obj1", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("obj2", "Obj2", false, false, false))

  var want2 = newObjectDefinition("Obj1", false)
  want2.addFieldDefinition(newFieldDefinition("obj11", "Obj11", false, false, false))

  var want3 = newObjectDefinition("Obj11", false)
  want3.addFieldDefinition(newFieldDefinition("a", "int64", false, false, false))

  var want4 = newObjectDefinition("Obj2", false)
  want4.addFieldDefinition(newFieldDefinition("b", "float64", false, false, false))

  check defs == @[want1, want2, want3, want4]

block:
  checkpoint "正常系: 配列"
  let j = """
{
  "a": [1,2,3],
  "b": ["a","b","c"]
}
""".parseJson
  var defs: seq[ObjectDefinition]
  j.parse(defs, 0, "Object", false, false, false)

  var want1 = newObjectDefinition("Object", false)
  want1.addFieldDefinition(newFieldDefinition("a", "int64", false, false, true))
  want1.addFieldDefinition(newFieldDefinition("b", "string", false, false, true))

  check defs == @[want1]

block:
  checkpoint "正常系: 配列のオブジェクト"
  let j = """
{
  "axis": [
    {"x":1, "y":2.0},
    {"x":3, "y":4.0}
  ],
  "person": {
    "name": "john",
    "age": 20,
    "hobby": ["dance", "game"],
    "parent": [
      {
        "name": "dad",
        "age": 50
      },
      {
        "name": "mam",
        "age": 51
      }
    ],
    "admin": true
  },
  "count": 2,
  "nulls": [null, null, null],
  "nulls2": []
}
""".parseJson
  var defs: seq[ObjectDefinition]
  j.parse(defs, 0, "Object", false, false, false)

  var want1 = newObjectDefinition("Object", false)
  want1.addFieldDefinition(newFieldDefinition("axis", "Axis", false, false, true))
  want1.addFieldDefinition(newFieldDefinition("person", "Person", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("count", "int64", false, false, false))
  want1.addFieldDefinition(newFieldDefinition("nulls", "NilType", false, false, true))
  want1.addFieldDefinition(newFieldDefinition("nulls2", "NilType", false, false, true))

  var want2 = newObjectDefinition("Axis", false)
  want2.addFieldDefinition(newFieldDefinition("x", "int64", false, false, false))
  want2.addFieldDefinition(newFieldDefinition("y", "float64", false, false, false))

  var want3 = newObjectDefinition("Person", false)
  want3.addFieldDefinition(newFieldDefinition("name", "string", false, false, false))
  want3.addFieldDefinition(newFieldDefinition("age", "int64", false, false, false))
  want3.addFieldDefinition(newFieldDefinition("hobby", "string", false, false, true))
  want3.addFieldDefinition(newFieldDefinition("parent", "Parent", false, false, true))
  want3.addFieldDefinition(newFieldDefinition("admin", "bool", false, false, false))

  var want4 = newObjectDefinition("Parent", false)
  want4.addFieldDefinition(newFieldDefinition("name", "string", false, false, false))
  want4.addFieldDefinition(newFieldDefinition("age", "int64", false, false, false))

  check defs == @[want1, want2, want3, want4]
