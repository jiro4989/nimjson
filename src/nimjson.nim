import nimjson/util
import json, os, strformat, parseopt, logging

type
  Options = ref object
    args: seq[string]
    useHelp, useVersion, useDebug: bool
    outFile: string
    objectName: string

const
  appName = "nimjson"
  version = &"""{appName} command version 1.0.0
Copyright (c) 2019 jiro4989
Released under the MIT License.
https://github.com/jiro4989/nimjson"""
  doc = &"""
{appName} prints a converted Nim object type string from JSON file or string.

Usage:
    {appName} [options] [files...]
    {appName} (-h | --help)
    {appName} (-v | --version)

Options:
    -h, --help                       Print this help
    -v, --version                    Print version
    -X, --debug                      Debug on
    -o, --out-file:FILE_PATH         Write file path
    -O, --object-name:OBJECT_NAME    Set object type name
"""

proc getCmdOpts*(params: seq[string]): Options =
  var optParser = initOptParser(params)
  new result
  result.objectName = "Object"

  # コマンドラインオプションを取得
  for kind, key, val in optParser.getopt():
    case kind
    of cmdArgument:
      result.args.add(key)
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h":
        echo doc
        result.useHelp = true
        return
      of "version", "v":
        echo version
        result.useVersion = true
        return
      of "debug", "X":
        result.useDebug = true
      of "out-file", "o":
        result.outFile = val
      of "object-name", "O":
        result.objectName = val
    of cmdEnd:
      assert false # cannot happen
    
proc setLogger(opts: Options) =
  if opts.useDebug:
    newConsoleLogger(lvlAll).addHandler()

when isMainModule:
  let opts = commandLineParams().getCmdOpts()
  if opts.useHelp or opts.useVersion: quit 0
  setLogger(opts)
  debug &"Command line options = {opts[]}"

  var outFile =
    if opts.outFile != "":
      debug &"Open file: {opts.outFile}"
      opts.outFile.open(fmWrite)
    else:
      debug "Open stdout"
      stdout

  if 0 < opts.args.len():
    debug &"START: Process arguments: args = {opts.args}"
    for inFile in opts.args:
      outFile.write(inFile.parseFile().toTypeString(opts.objectName))
    debug "END: Process arguments"
  else:
    debug "START: Process stdin"
    var str: string
    var line: string
    while stdin.readLine(line):
      str.add(line)
    outFile.write(str.parseJson().toTypeString(opts.objectName))
    debug "END: Process stdin"
  outFile.close()

  debug "Success: nimjson"