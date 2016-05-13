//
//  Validator.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/12/16.
//
//

public protocol Validator {
    public func validate(value: Any) -> Bool
}

extension Validator {
    public func validate(value: Any) -> Bool {
        return false
    }
}

public struct LengthValidator: Validator {
    public var min: Int.min
    public var max: Int.max
    
    // TOOD: Add implementation for strict. Make type independent
    public func validate(value: Any) -> Bool {
        if let countable = value as? CollectionType {
            return countable.count >= self.min && countable.count <= self.max
        } else if let string = value as? String {
            return string.characters.count >= self.min && string.characters.count <= self.max
        }
    }
}

public struct RangeValidator {
    var from: Any
    var to: Any
    // TOOD: Add implementation
}

public struct PresentValidator {
    // TOOD: Add implementation
}