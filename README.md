# nimjson


[![CI Status](https://github.com/jiro4989/nimjson/workflows/build/badge.svg)](https://github.com/jiro4989/nimjson/actions)
[![Install Status](https://nimble.directory/ci/badges/nimjson/nimdevel/status.svg)](https://nimble.directory/ci/badges/nimjson/nimdevel/output.html)
[![Doc Status](https://nimble.directory/ci/badges/nimjson/nimdevel/docstatus.svg)](https://nimble.directory/ci/badges/nimjson/nimdevel/doc_build_output.html)

nimjson generates nim object definitions from json documents.
This was inspired by [gojson](https://github.com/ChimeraCoder/gojson).

## Development

* Nim (stable version)

## Usage examples (CLI)

`nimjson` writes `NilType` type if a value or a first value of an array is null.
Please fix `NilType` type yourself.

### Large JSON

```bash
% curl -s https://api.github.com/repos/jiro4989/nimjson | nimjson -O:Repository
type
  NilType = ref object
  Repository = ref object
    id: int64
    node_id: string
    name: string
    full_name: string
    private: bool
    owner: Owner
    html_url: string
    description: string
    fork: bool
    url: string
    forks_url: string
    keys_url: string
    collaborators_url: string
    teams_url: string
    hooks_url: string
    issue_events_url: string
    events_url: string
    assignees_url: string
    branches_url: string
    tags_url: string
    blobs_url: string
    git_tags_url: string
    git_refs_url: string
    trees_url: string
    statuses_url: string
    languages_url: string
    stargazers_url: string
    contributors_url: string
    subscribers_url: string
    subscription_url: string
    commits_url: string
    git_commits_url: string
    comments_url: string
    issue_comment_url: string
    contents_url: string
    compare_url: string
    merges_url: string
    archive_url: string
    downloads_url: string
    issues_url: string
    pulls_url: string
    milestones_url: string
    notifications_url: string
    labels_url: string
    releases_url: string
    deployments_url: string
    created_at: string
    updated_at: string
    pushed_at: string
    git_url: string
    ssh_url: string
    clone_url: string
    svn_url: string
    homepage: string
    size: int64
    stargazers_count: int64
    watchers_count: int64
    language: string
    has_issues: bool
    has_projects: bool
    has_downloads: bool
    has_wiki: bool
    has_pages: bool
    forks_count: int64
    mirror_url: NilType
    archived: bool
    disabled: bool
    open_issues_count: int64
    license: License
    allow_forking: bool
    is_template: bool
    topics: seq[string]
    visibility: string
    forks: int64
    open_issues: int64
    watchers: int64
    default_branch: string
    temp_clone_token: NilType
    network_count: int64
    subscribers_count: int64
  Owner = ref object
    login: string
    id: int64
    node_id: string
    avatar_url: string
    gravatar_id: string
    url: string
    html_url: string
    followers_url: string
    following_url: string
    gists_url: string
    starred_url: string
    subscriptions_url: string
    organizations_url: string
    repos_url: string
    events_url: string
    received_events_url: string
    `type`: string
    site_admin: bool
  License = ref object
    key: string
    name: string
    spdx_id: string
    url: string
    node_id: string
```

### Simple JSON

```bash
% nimjson examples/primitive.json
type
  NilType = ref object
  Object = ref object
    stringField: string
    intField: int64
    floatField: float64
    boolField: bool
    nullField: NilType

% nimjson examples/array.json
type
  NilType = ref object
  Object = ref object
    strArray: seq[string]
    intArray: seq[int64]
    floatArray: seq[float64]
    boolArray: seq[bool]
    nullArray: seq[NilType]
    emptyArray: seq[NilType]

% nimjson examples/object.json
type
  NilType = ref object
  Object = ref object
    point: Point
    length: int64
    responseCode: string
    debugFlag: bool
    rectangles: seq[Rectangles]
  Point = ref object
    x: float64
    y: float64
  Rectangles = ref object
    width: int64
    height: int64
```

### JSON Schema

`nimjson` supports partially [JSON Schema](https://json-schema.org/understanding-json-schema/index.html).
`nimjson` generates Nim type definition with JSON Schema when you enable `-j` option.

```bash
$ nimjson -j examples/json_schema.json
type
  Object = ref object
    `type`: string
    id: string
    timestamp: string
    stream: string
    consumer: string
    consumer_seq: string
    stream_seq: string
    deliveries: int64
    domain: Option[string]
```

It is wrapped by default in the `Option` type that properties not included in the `required` parameter of JSON Schema.
If you don't want to use `Option` type, you can use `--disable-option` option.

```bash
$ nimjson -j --disable-option examples/json_schema.json
type
  Object = ref object
    `type`: string
    id: string
    timestamp: string
    stream: string
    consumer: string
    consumer_seq: string
    stream_seq: string
    deliveries: int64
    domain: string
```

`nimjson` supports `$ref` and `$defs` keywords.
But it doesn't support URL of `$ref`.

This is supported:

```json
{
  "$id": "https://example.com/product.schema.json",
  "type": "object",
  "properties": {
    "product": { "$ref": "#/$defs/product" },
    "product2": { "$ref": "#/$defs/product2" }
  },
  "$defs": {
    "product": { "type": "string" },
    "product2": { "type": "array", "items": { "type": "string" } }
  }
}
```

This is NOT supported:

```json
{
  "$id": "https://example.com/product.schema.json",
  "type": "object",
  "properties": {
    "product": { "$ref": "https://example.com/schemas/address" }
  }
}
```

## Usage examples (API)

```nim
import std/json

import nimjson

echo """{"keyStr":"str", "keyInt":1}""".parseJson().toTypeString()

# Output:
# type
#   NilType = ref object
#   Object = ref object
#     keyStr: string
#     keyInt: int64

echo "examples/primitive.json".parseFile().toTypeString("testObject")

# Output:
# type
#   NilType = ref object
#   TestObject = ref object
#     stringField: string
#     intField: int64
#     floatField: float64
#     boolField: bool
#     nullField: NilType
```

## Installation

### Nim users

```bash
nimble install nimjson
```

### Linux users (Debian base distros)

```bash
wget https://github.com/jiro4989/nimjson/releases/download/v2.0.0/nimjson_2.0.0_amd64.deb
sudo dpkg -i ./nimjson*.deb
```

### Linux users (RHEL compatible distros)

```bash
yum install https://github.com/jiro4989/nimjson/releases/download/v2.0.0/nimjson-2.0.0-1.el7.x86_64.rpm
```

## Help

`nimjson -h`

    nimjson generates nim object definitions from json documents.
    
    Usage:
        nimjson [options] [files...]
        nimjson (-h | --help)
        nimjson (-v | --version)
    
    Options:
        -h, --help                       Print this help
        -v, --version                    Print version
        -X, --debug                      Debug on
        -o, --out-file:FILE_PATH         Write file path
        -O, --object-name:OBJECT_NAME    Set object type name
        -p, --public-field               Public fields
        -q, --quote-field                Quotes all fields

## License

MIT

## Document

- https://jiro4989.github.io/nimjson/nimjson.html

## Web application of nimjson

I created simple nimjson on web application.

https://jiro4989.github.io/nimjson

Javascript library of nimjson of the application is generated by this
module (`nimble js`).

