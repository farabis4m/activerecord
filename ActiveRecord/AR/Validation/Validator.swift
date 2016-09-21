//
//  Validator.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/12/16.
//
//

public protocol Validator {
    @discardableResult
    func validate(_ record: ActiveRecord, attribute: String, value: Any?, errors: inout Errors) -> Bool
}

extension Validator {
    public func validate(_ record: ActiveRecord, attribute: String, value: Any?, errors: inout Errors) -> Bool {
        return false
    }
}

public struct LengthValidator: Validator {
    public var min = Int.min
    public var max = Int.max
    
    // TOOD: Add implementation for strict. Make type independent
    public func validate(_ record: ActiveRecord, attribute: String, value: Any?, errors: inout Errors) -> Bool {
        if let countable = value as? [Any] {
            return countable.count >= self.min && countable.count <= self.max
        } else if let countable = value as? Dictionary<String, Any> {
            return countable.count >= self.min && countable.count <= self.max
        } else if let string = value as? String {
            return string.characters.count >= self.min && string.characters.count <= self.max
        }
        return false
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
