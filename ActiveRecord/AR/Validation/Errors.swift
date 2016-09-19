//
//  Errors.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/12/16.
//
//

import ApplicationSupport

public enum Error: Error {
    case blank
    case absent
    case tooShort(length: Int)
    case tooLong(length: Int)
    case wrongLength(length: Int)
    case taken
    case invalid
    
    case notANumber
    
    case lessThanOrEqual(value: Any)
    case lessThan(value: Any)
    case greaterThanOrEqual(value: Any)
    case greaterThan(value: Any)
    case equalTo(value: Any)
    
    public var rawValue: String {
        switch self {
        case .blank: return "blank"
        case .absent: return "present"
        case .tooShort: return "too_short"
        case .tooLong: return "too_long"
        case .wrongLength: return "wrong_length"
        case .taken: return"taken"
        case .invalid: return "invalid"
            
        case .notANumber: return "not_a_number"
            
        case .lessThanOrEqual: return "less_than_or_equal_to"
        case .lessThan: return "less_than"
        case .greaterThanOrEqual: return "greater_than"
        case .greaterThan: return "greater_than_or_equal_to"
        case .equalTo: return "equal_to"
            
        default: return "empty_error"
        }
    }
}

public struct Errors {
    
    var model: ActiveRecord
    
    var attributes = Dictionary<String, Error>()
    public mutating func add(_ attribute: String, message: Error) {
        self.attributes[attribute] = message
        self._messages << (type(of: self.model).modelName + "." + attribute + "." + message.rawValue)
    }
    fileprivate var _messages = Array<String>()
    public var messages: [String] {
        return base + _messages
    }
    
    public var base = Array<String>()
    public var isEmpty: Bool { return self._messages.isEmpty && self.base.isEmpty }
    
    public func contains(_ attribute: String) -> Bool {
        return self.attributes[attribute] != nil
    }
    
    public init(model: ActiveRecord) {
        self.model = model
    }
}
