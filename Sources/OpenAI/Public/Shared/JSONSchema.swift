//
//  JSONSchema.swift
//
//
//  Created by James Rochabrun on 8/10/24.
//

import Foundation

// MARK: JSONSchemaType

/// Supported schemas
///
/// Structured Outputs supports a subset of the JSON Schema language.
///
/// Supported types
///
/// The following types are supported for Structured Outputs:
///
/// String
/// Number
/// Boolean
/// Object
/// Array
/// Enum
/// anyOf
public enum JSONSchemaType: Codable, Equatable {
  case string
  case number
  case integer
  case boolean
  case object
  case array
  case null
  case union([JSONSchemaType])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let string = try? container.decode(String.self) {
      switch string {
      case "string": self = .string
      case "number": self = .number
      case "integer": self = .integer
      case "boolean": self = .boolean
      case "object": self = .object
      case "array": self = .array
      case "null": self = .null
      default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown type: \(string)")
      }
    } else if let array = try? container.decode([String].self) {
      let types = try array.map { typeString -> JSONSchemaType in
        guard let type = JSONSchemaType(rawValue: typeString) else {
          throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown type in union: \(typeString)")
        }
        return type
      }
      self = .union(types)
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a string or an array of strings")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string: try container.encode("string")
    case .number: try container.encode("number")
    case .integer: try container.encode("integer")
    case .boolean: try container.encode("boolean")
    case .object: try container.encode("object")
    case .array: try container.encode("array")
    case .null: try container.encode("null")
    case .union(let types): try container.encode(types.map { $0.rawValue })
    }
  }

  public static func optional(_ type: JSONSchemaType) -> JSONSchemaType {
    return .union([type, .null])
  }

  private init?(rawValue: String) {
    switch rawValue {
    case "string": self = .string
    case "number": self = .number
    case "integer": self = .integer
    case "boolean": self = .boolean
    case "object": self = .object
    case "array": self = .array
    case "null": self = .null
    default: return nil
    }
  }

  private var rawValue: String {
    switch self {
    case .string: return "string"
    case .number: return "number"
    case .integer: return "integer"
    case .boolean: return "boolean"
    case .object: return "object"
    case .array: return "array"
    case .null: return "null"
    case .union: fatalError("Union type doesn't have a single raw value")
    }
  }
}

public class JSONSchema: Codable, Equatable {

  public let type: JSONSchemaType?
  public let description: String?
  public var properties: [String: JSONSchema]?
  public var items: JSONSchema?
  /// To use Structured Outputs, all fields or function parameters [must be specified as required.](https://platform.openai.com/docs/guides/structured-outputs/all-fields-must-be-required)
  /// Although all fields must be required (and the model will return a value for each parameter), it is possible to emulate an optional parameter by using a union type with null.
  public let required: [String]?
  /// Structured Outputs only supports generating specified keys / values, so we require developers to set additionalProperties: false to opt into Structured Outputs.
  public let additionalProperties: Bool?
  public let `enum`: [String]?
  public var ref: String?
  public var defs: [String: JSONSchema]?
  public var anyOf: [JSONSchema]?
  public var strict: Bool?

  public init(
    type: JSONSchemaType? = nil,
    description: String? = nil,
    properties: [String: JSONSchema]? = nil,
    items: JSONSchema? = nil,
    required: [String]? = nil,
    additionalProperties: Bool? = nil,
    enum: [String]? = nil,
    ref: String? = nil,
    defs: [String: JSONSchema]? = nil,
    anyOf: [JSONSchema]? = nil,
    strict: Bool? = nil
  ) {
    self.type = type
    self.description = description
    self.properties = properties
    self.items = items
    self.required = required
    self.additionalProperties = additionalProperties
    self.enum = `enum`
    self.ref = ref
    self.defs = defs
    self.anyOf = anyOf
    self.strict = strict
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    if let ref = ref {
      try container.encode(ref, forKey: .ref)
      return
    }

    try container.encodeIfPresent(type, forKey: .type)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encodeIfPresent(properties, forKey: .properties)
    try container.encodeIfPresent(items, forKey: .items)
    try container.encodeIfPresent(required, forKey: .required)
    try container.encodeIfPresent(additionalProperties, forKey: .additionalProperties)
    try container.encodeIfPresent(`enum`, forKey: .enum)
    try container.encodeIfPresent(defs, forKey: .defs)
    try container.encodeIfPresent(anyOf, forKey: .anyOf)
    try container.encodeIfPresent(strict, forKey: .strict)
  }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let ref = try? container.decode(String.self, forKey: .ref) {
      self.ref = ref
      type = nil
      description = nil
      properties = nil
      items = nil
      required = nil
      additionalProperties = nil
      `enum` = nil
      defs = nil
      anyOf = nil
      strict = nil
      return
    }

    type = try container.decodeIfPresent(JSONSchemaType.self, forKey: .type)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    properties = try container.decodeIfPresent([String: JSONSchema].self, forKey: .properties)
    items = try container.decodeIfPresent(JSONSchema.self, forKey: .items)
    required = try container.decodeIfPresent([String].self, forKey: .required)
    additionalProperties = try container.decodeIfPresent(Bool.self, forKey: .additionalProperties)
    `enum` = try container.decodeIfPresent([String].self, forKey: .enum)
    defs = try container.decodeIfPresent([String: JSONSchema].self, forKey: .defs)
    anyOf = try container.decodeIfPresent([JSONSchema].self, forKey: .anyOf)
    strict = try container.decodeIfPresent(Bool.self, forKey: .strict)
    ref = nil
  }

  public static func == (lhs: JSONSchema, rhs: JSONSchema) -> Bool {
    lhs.type == rhs.type && lhs.description == rhs.description && lhs.properties == rhs.properties && lhs.items == rhs.items && lhs.required == rhs.required
      && lhs.additionalProperties == rhs.additionalProperties && lhs.enum == rhs.enum && lhs.ref == rhs.ref && lhs.defs == rhs.defs && lhs.anyOf == rhs.anyOf && lhs.strict == rhs.strict
  }

  private enum CodingKeys: String, CodingKey {
    case type, description, properties, items, required, additionalProperties, `enum`, strict, anyOf
    case ref = "$ref"
    case defs = "$defs"
  }
}
