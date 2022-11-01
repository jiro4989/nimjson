import nimjson

echo """{"keyStr":"str", "keyInt":1}""".toTypeString()
echo "../primitive.json".readFile().toTypeString("testObject")
echo "../json_schema.json".readFile().toTypeString("testObject",
    jsonSchema = true)
