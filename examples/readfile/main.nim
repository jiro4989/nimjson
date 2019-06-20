import nimjson
import json

echo """{"keyStr":"str", "keyInt":1}""".parseJson().toTypeString()
echo "../primitive.json".parseFile().toTypeString("testObject")