discard """
  exitCode: 0
  output: ""
"""

import std/unittest

include nimjsonpkg/json_schema_parser

block:
  checkpoint "proc parseAndGetString"
  let j = """{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://nats.io/schemas/jetstream/advisory/v1/nak.json",
  "description": "Advisory published when a message was naked using a AckNak acknowledgement",
  "title": "io.nats.jetstream.advisory.v1.nak",
  "type": "object",
  "required": [
    "type",
    "id",
    "timestamp",
    "stream",
    "consumer",
    "consumer_seq",
    "stream_seq",
    "deliveries"
  ],
  "additionalProperties": false,
  "properties": {
    "type": {
      "type": "string",
      "const": "io.nats.jetstream.advisory.v1.nak"
    },
    "id": {
      "type": "string",
      "description": "Unique correlation ID for this event"
    },
    "timestamp": {
      "type": "string",
      "description": "The time this event was created in RFC3339 format"
    },
    "stream": {
      "type": "string",
      "description": "The name of the stream where the message is stored"
    },
    "consumer": {
      "type": "string",
      "description": "The name of the consumer where the message was naked"
    },
    "consumer_seq": {
      "type": "string",
      "minimum": 1,
      "description": "The sequence of the message in the consumer that was naked"
    },
    "stream_seq": {
      "type": "string",
      "minimum": 1,
      "description": "The sequence of the message in the stream that was naked"
    },
    "deliveries": {
      "type": "integer",
      "minimum": 1,
      "description": "The number of deliveries that were attempted"
    },
    "domain": {
      "type": "string",
      "minimum": 1,
      "description": "The domain of the JetStreamServer"
    }
  }
}"""
  block:
    checkpoint "ok: sample json schema"
    let got = j.parseAndGetString("Repository", false, false, false)
    check got == """type
  Repository = ref object
    `type`: string
    id: string
    timestamp: string
    stream: string
    consumer: string
    consumer_seq: string
    stream_seq: string
    deliveries: int64
    domain: Option[string]"""

  block:
    checkpoint "ok: no Option field when `disableOption` is true"
    let got = j.parseAndGetString("Repository", false, false, true)
    check got == """type
  Repository = ref object
    `type`: string
    id: string
    timestamp: string
    stream: string
    consumer: string
    consumer_seq: string
    stream_seq: string
    deliveries: int64
    domain: string"""

  block:
    checkpoint "ok: nested object"
    let j2 = """
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://example.com/product.schema.json",
  "title": "Product",
  "description": "A product from Acme's catalog",
  "type": "object",
  "properties": {
    "productId": {
      "description": "The unique identifier for a product",
      "type": "integer"
    },
    "productName": {
      "description": "Name of the product",
      "type": "string"
    },
    "price": {
      "description": "The price of the product",
      "type": "number",
      "exclusiveMinimum": 0
    },
    "tags": {
      "description": "Tags for the product",
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "dimensions": {
      "type": "object",
      "properties": {
        "length": {
          "type": "number"
        },
        "width": {
          "type": "number"
        },
        "height": {
          "type": "number"
        }
      },
      "required": [ "length", "width", "height" ]
    }
  },
  "required": [ "productId", "productName", "price" ]
}
"""
    let got = j2.parseAndGetString("Repository", false, false, true)
    check got == """type
  Dimensions = ref object
    length: float64
    width: float64
    height: float64
  Repository = ref object
    productId: int64
    productName: string
    price: float64
    tags: seq[string]
    dimensions: Dimensions"""

block:
  checkpoint "proc typeToNimTypeName"
  block:
    checkpoint "ok: supported type"
    check "string".typeToNimTypeName == "string"
    check "integer".typeToNimTypeName == "int64"
    check "number".typeToNimTypeName == "float64"
    check "boolean".typeToNimTypeName == "bool"
    check "null".typeToNimTypeName == "NilType"

  block:
    checkpoint "ng: unsupported type"
    expect UnsupportedTypeError:
      discard "object".typeToNimTypeName
    expect UnsupportedTypeError:
      discard "array".typeToNimTypeName
    expect UnsupportedTypeError:
      discard "sushi".typeToNimTypeName
    expect UnsupportedTypeError:
      discard "".typeToNimTypeName

block:
  checkpoint "proc validateRef"
  block:
    checkpoint "ok: supported $ref"
    Property(`$ref`: "#/$defs/name").validateRef()
    Property(`$ref`: "#").validateRef()
  block:
    checkpoint "ng: unsupported $ref"
    expect UnsupportedRefError:
      Property(`$ref`: "https://example.com/schemas/address").validateRef()