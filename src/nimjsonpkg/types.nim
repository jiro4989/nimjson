from std/strutils import replace
from std/strformat import `&`

type
  ObjectDefinition* = object
    name: string
    fields: seq[FieldDefinition]
    isRef: bool
    isNilType: bool

  FieldDefinition* = object
    name*: string
    typ*: string
    isPublic*: bool
    isNormalized*: bool
    isBackquoted*: bool
    isSeq: bool

func newObjectDefinition*(name: string, isNilType: bool): ObjectDefinition =
  result.name = name
  result.isRef = true
  result.isNilType = isNilType

proc addFieldDefinition*(self: var ObjectDefinition,
    fieldDef: FieldDefinition) =
  self.fields.add(fieldDef)

func removeUnusedChars(s: string): string =
  ## フィールド名や型名に使用不可能な文字列を削除する。
  s.replace(",").replace("'")

func normalize(self: FieldDefinition): FieldDefinition =
  ## フィールド名や型名に使用不可能な文字列を削除する。
  result = self
  if self.isNormalized:
    return

  result.isNormalized = true
  result.name = result.name.removeUnusedChars
  result.typ = result.typ.removeUnusedChars

func backquote(s: string, force: bool): string =
  ## 必要であればバッククオートで括る。
  ## Nimではフィールド名や型名に記号などの特別な文字を使用可能だが、その場合はバッククオートで括る必要がある。
  ##
  ## See:
  ## * https://datatracker.ietf.org/doc/html/rfc8259#section-7
  const needQuoteChars = [
    # 0x22.char, # quotation mark
      # 0x5c.char, # reverse solidus
      # 0x2f.char, # solidus
      # 0x62.char, # backspace
      # 0x66.char, # form feed
      # 0x6e.char, # line feed
      # 0x72.char, # carriage return
      # 0x74.char, # tab
      # 0x75.char, # 4hexdig
    '\\',
    '/',
    ' ',
    '-',
    '*',
  ]
  const reservedKeyword = [
    "type",
    "object",
    "enum",
    "let",
    "const",
    "var",
  ]
  result = &"`{s}`"
  if force:
    return
  for ch in needQuoteChars:
    if ch in s:
      return
  for keyword in reservedKeyword:
    if s == keyword:
      return
  return s

func backquote(self: FieldDefinition, force: bool): FieldDefinition =
  ## 必要であればバッククオートで括る。
  ## ``force`` を有効にすれば必ずバッククオートで括る。
  result = self
  if self.isBackquoted:
    return

  result.isBackquoted = true
  result.name = result.name.backquote(force)
  result.typ = result.typ.backquote(force)

func newFieldDefinition*(name: string, typ: string, isPublic: bool,
    forceBackquote: bool, isSeq: bool): FieldDefinition =
  result.name = name
  result.typ = typ
  result.isPublic = isPublic
  result.isSeq = isSeq
  result = result.normalize
  result = result.backquote(forceBackquote)
