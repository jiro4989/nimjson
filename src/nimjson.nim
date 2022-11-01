import std/json

import ./nimjsonpkg/parser
import ./nimjsonpkg/json_schema_parser

proc toTypeString*(self: JsonNode, objName = "Object",
    publicField = false, quoteField = false): string =
  ## Generates nim object definitions string from ``JsonNode``.
  ## Returns a public field string if ``publicField`` was true.
  ##
  ## **Japanese:**
  ##
  ## ``JsonNode`` をNimのObject定義の文字列に変換して返却する。
  ## ``objName`` が定義するObjectの名前になる。
  ## ``publicField`` を指定すると、公開フィールドとして文字列を返却する。
  ##
  ## **Note:**
  ## * 値が ``null`` あるいは配列の最初の要素が ``null`` や値が空配列の場合は、
  ##   型が `nilType <#nilType>`_ になる。
  runnableExamples:
    import std/json
    from std/strutils import split

    let typeStr = """{"keyStr":"str",
                      "keyInt":1,
                      "keyFloat":1.1,
                      "keyBool":true}""".parseJson().toTypeString()
    let typeLines = typeStr.split("\n")
    doAssert typeLines[0] == "type"
    doAssert typeLines[1] == "  NilType = ref object"
    doAssert typeLines[2] == "  Object = ref object"
    doAssert typeLines[3] == "    keyStr: string"
    doAssert typeLines[4] == "    keyInt: int64"
    doAssert typeLines[5] == "    keyFloat: float64"
    doAssert typeLines[6] == "    keyBool: bool"

  return self.parseAndGetString(objectName = objName, isPublic = publicField,
      forceBackquote = quoteField)

proc toTypeString*(jsonString: string, objName = "Object", publicField = false, quoteField = false, jsonSchema = false, disableOption = false): string =
  if jsonSchema:
    return jsonString.parseAndGetString(objName, publicField, quoteField, disableOption)

  return jsonString.parseJson.toTypeString(objName, publicField, quoteField)

when not defined(js):
  import std/logging
  import std/os
  import std/parseopt
  import std/strformat

  type
    Options = ref object
      args: seq[string]
      useHelp, useVersion, useDebug: bool
      outFile: string
      objectName: string
      usePublicField: bool
      useQuoteField: bool
      useJsonSchema: bool
      disableOption: bool

  const
    appName = "nimjson"
    version = &"""{appName} command version 3.0.0
Copyright (c) 2019 jiro4989
Released under the MIT License.
https://github.com/jiro4989/nimjson"""
    doc = &"""
{appName} generates nim object definitions from json documents.

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
    -p, --public-field               Public fields
    -q, --quote-field                Quotes all fields
"""

  proc getCmdOpts(params: seq[string]): Options =
    ## コマンドライン引数を解析して返す。
    ## helpとversionが見つかったらテキストを標準出力して早期リターンする。
    var optParser = initOptParser(params)
    new result
    result.objectName = "Object"

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
        of "public-field", "p":
          result.usePublicField = true
        of "quote-field", "q":
          result.useQuoteField = true
        of "json-schema", "j":
          result.useJsonSchema = true
        of "disable-option":
          result.disableOption = true
      of cmdEnd:
        assert false # cannot happen

  proc setLogger(opts: Options) =
    ## デバッグログ出力フラグ(useDebug)がtrueのときだけログ出力ハンドラをセットす
    ## る。
    if opts.useDebug:
      newConsoleLogger(lvlAll, verboseFmtStr).addHandler()

  when isMainModule:
    let opts = commandLineParams().getCmdOpts()
    if opts.useHelp or opts.useVersion: quit 0
    setLogger(opts)
    debug &"Command line options = {opts[]}"

    # 出力ファイルパスを指定していたらファイルを出力先に指定
    # 未指定の場合は標準出力が出力先になる
    var outFile =
      if opts.outFile != "":
        debug &"Open file: {opts.outFile}"
        opts.outFile.open(fmWrite)
      else:
        debug "Open stdout"
        stdout

    # 引数（ファイルパス）が存在したらファイルを読み込んで
    # NimのObject文字列に変換する。
    # 引数未指定の場合は標準入力待ちになる。
    if 0 < opts.args.len():
      debug &"START: Process arguments: args = {opts.args}"

      # 入力ファイルが複数あっても出力先は1つである。
      # もともと入力ファイルは1つの想定であり、
      # 2つ処理できるようにしてるのはオマケ機能である。
      for inFile in opts.args:
        let typeString = inFile.readFile.toTypeString(opts.objectName, opts.usePublicField, opts.useQuoteField, opts.useJsonSchema, opts.disableOption)
        outFile.write(typeString)
      debug "END: Process arguments"
    else:
      debug "START: Process stdin"
      var str: string
      var line: string
      while stdin.readLine(line):
        str.add(line)
      let typeString = str.toTypeString(opts.objectName, opts.usePublicField, opts.useQuoteField, opts.useJsonSchema, opts.disableOption)
      outFile.write(typeString)
      debug "END: Process stdin"

    debug "Success: nimjson"
    outFile.close()
