from std/strutils import toUpperAscii

func headUpper*(str: string): string =
  ## Returns a string with the first character converted to uppercase,
  ## not UpperCamelCase.
  $(str[0].toUpperAscii() & str[1..^1])
