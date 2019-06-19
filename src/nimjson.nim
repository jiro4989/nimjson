import nimjson/util
import json, os

when isMainModule:
  let args = os.commandLineParams()
  echo args[0].parseFile().toTypeString()
