import unittest
import sequtils

include nimjson/util

proc removeIndent(s: string): string =
  for line in s.split("\n").filterIt(0 < it.len()):
    let pos = line.split("|")[0].len()
    result.add(line[pos+1..^1].join())
    result.add("\n")

doAssert removeIndent("""
  |abc
  |  def""") == "abc\n  def\n"

echo """
  {
    "int":1,
    "str":"string",
    "float":1.24,
    "bool":true
  }""".parseJson().toTypeString()

echo """
  [{
    "int":1,
    "str":"string",
    "float":1.24,
    "bool":true
  }]""".parseJson().toTypeString()

echo """[1, 2, 3]""".parseJson().toTypeString()

echo """{"str":"string1", "int":1, "float":1.15, "array":[1, 2, 3],
          "testObject":{"int":1, "obj2":{"str":"s", "bool2":true, "bool3":false},
          "str":"s", "float":1.12},
          "array":[null, 1, 2, 3],
          "objectArray":[{"int":1, "bool":true, "b":false}, {"int":2, "bool":false, "b":true}],
        }""".parseJson().toTypeString()

suite "proc toTypeString":
  test "Primitive types":
    check """
      {
        "int":1,
        "str":"string",
        "float":1.24,
        "bool":true
      }""".parseJson().toTypeString() == """
      |type
      |  Object = ref object
      |    int: int64
      |    str: string
      |    float: float64
      |    bool: bool""".removeIndent()
  test "Array value":
    check """
      {
        "int":[1, 2, 3],
        "str":["str", "str"],
        "float":[1.1, 1.2, 1.3],
        "trueBool":[true, false],
        "falseBool":[false, true]
      }""".parseJson().toTypeString() == """
      |type
      |  Object = ref object
      |    int: seq[int64]
      |    str: seq[string]
      |    float: seq[float64]
      |    trueBool: seq[bool]
      |    falseBool: seq[bool]""".removeIndent()
  test "Object value":
    check """
      {
        "obj1":{"int":1, "str":"strval"},
        "obj2":{"fal":false, "str":null}
      }""".parseJson().toTypeString() == """
      |type
      |  Object = ref object
      |    obj1: Obj1
      |    obj2: Obj2
      |  Obj1 = ref object
      |    int: int64
      |    str: string
      |  Obj2 = ref object
      |    fal: bool
      |    str: JNull""".removeIndent()
  test "Array object":
    check """
      {
        "obj1":[{"int":1, "str":"strval"}, {"int":2, "str":"strval2"}],
        "obj2":{"fal":false, "str":null, "obj":[{"fal":false}, {"fal":false}], "v":1, "v2":2, "objobj":{"i":1}},
        "obj3":[{"int":1, "str":"strval"}, {"int":2, "str":"strval2"}],
        "obj4":{"objX":{"i":12}}
      }""".parseJson().toTypeString() == """
      |type
      |  Object = ref object
      |    obj1: seq[Obj1]
      |    obj2: Obj2
      |    obj3: seq[Obj3]
      |    obj4: Obj4
      |  Obj1 = ref object
      |    int: int64
      |    str: string
      |  Obj2 = ref object
      |    fal: bool
      |    str: JNull
      |    obj: seq[Obj]
      |    v: int64
      |    v2: int64
      |    objobj: Objobj
      |  Obj3 = ref object
      |    int: int64
      |    str: string
      |  Obj4 = ref object
      |    objX: ObjX
      |  Obj = ref object
      |    fal: bool
      |  Objobj = ref object
      |    i: int64
      |  ObjX = ref object
      |    i: int64""".removeIndent()