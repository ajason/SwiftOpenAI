//
//  OpenAIErrorResponse.swift
//
//
//  Created by James Rochabrun on 11/13/23.
//

import Foundation

/*
 {
   "error": {
     "message": "Invalid parameter: messages with role 'tool' must be a response to a preceeding message with 'tool_calls'.",
     "type": "invalid_request_error",
     "param": "messages.[2].role",
     "code": null
   }
 }
 */

public struct OpenAIErrorResponse: Codable {

  public let error: Error

  public struct Error: Codable {
    public let message: String?
    public let type: String?
    public let param: String?
    public let code: String?

    enum CodingKeys: String, CodingKey {
      case message
      case type
      case param
      case code
    }
  }

  enum CodingKeys: String, CodingKey {
    case error
  }
}
