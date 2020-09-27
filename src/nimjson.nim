include nimjsonpkg/util

when not defined(js):
  import os, parseopt, logging

  type
    Options = ref object
      args: seq[string]
      useHelp, useVersion, useDebug: bool
      outFile: string
      objectName: string
      usePublicField: bool

  const
    appName = "nimjson"
    version = &"""{appName} command version 1.2.8
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
        outFile.write(inFile.parseFile().toTypeString(opts.objectName,
            opts.usePublicField))
      debug "END: Process arguments"
    else:
      debug "START: Process stdin"
      var str: string
      var line: string
      while stdin.readLine(line):
        str.add(line)
      outFile.write(str.parseJson().toTypeString(opts.objectName,
          opts.usePublicField))
      debug "END: Process stdin"

    debug "Success: nimjson"
    outFile.close()
