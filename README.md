# nimjson

[![Build Status](https://travis-ci.org/jiro4989/nimjson.svg?branch=master)](https://travis-ci.org/jiro4989/nimjson)
[![Build status](https://ci.appveyor.com/api/projects/status/fljtevgiqopth9sq?svg=true)](https://ci.appveyor.com/project/jiro4989/nimjson)

nimjson is a command to convert JSON string to Nim types.

## Development

    % nim -v
    Nim Compiler Version 0.20.0 [Linux: amd64]
    Compiled at 2019-06-06
    Copyright (c) 2006-2019 by Andreas Rumpf

    git hash: e7471cebae2a404f3e4239f199f5a0c422484aac
    active boot switches: -d:release

    % nimble -v
    nimble v0.10.2 compiled at 2019-06-15 22:10:02
    git hash: couldn't determine git hash

## Usage

```bash
% nimjson examples/1.json
% cat examples/1.json | nimjson
% cat examples/1.json | nimjson -o out.nim
```
