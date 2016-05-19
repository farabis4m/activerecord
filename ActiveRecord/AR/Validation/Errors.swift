//
//  Errors.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/12/16.
//
//

public enum Error: ErrorType {
    case Blank
    case Absent
    case TooShort(length: Int)
    case TooLong(length: Int)
    case WrongLength(length: Int)
    case Taken
    case Invalid
    
    case NotANumber
    
    case LessThanOrEqual(value: AnyType)
    case LessThan(value: AnyType)
    case GreaterThanOrEqual(value: AnyType)
    case GreaterThan(value: AnyType)
    case EqualTo(value: AnyType)
    
    var rawValue: String {
        switch self {
        case Blank: return "blank"
        case Absent: return "present"
        case TooShort: return "too_short"
        case TooLong: return "too_long"
        case WrongLength: return "wrong_length"
        case Taken: return"taken"
        case Invalid: return "invalid"
            
        case NotANumber: return "not_a_number"
            
        case LessThanOrEqual: return "less_than_or_equal_to"
        case LessThan: return "less_than"
        case GreaterThanOrEqual: return "greater_than"
        case GreaterThan: return "greater_than_or_equal_to"
        case EqualTo: return "equal_to"
            
        default: return "empty_error"
        }
    }
}

public struct Errors {
    
    var model: ActiveRecord
    
    var attributes = Dictionary<String, Error>()
    public mutating func add(attribute: String, message: Error) {
        self.attributes[attribute] = message
        self._messages << (self.model.dynamicType.modelName + "." + message.rawValue)
    }
    private var _messages = Array<String>()
    public var messages: [String] {
        return base + _messages
    }
    
    public var base = Array<String>()
    public var isEmpty: Bool { return self._messages.isEmpty && self.base.isEmpty }
    
    public func contains(attribute: String) -> Bool {
        return self.attributes[attribute] != nil
    }
    
    public init(model: ActiveRecord) {
        self.model = model
    }
}