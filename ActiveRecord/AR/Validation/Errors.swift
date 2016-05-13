//
//  Errors.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/12/16.
//
//

enum Errors: String {
    case Blank = "blank"
    case Absent = "present"
    case TooShort = "too_short"
    case TooLong = "too_long"
    case WrongLength = "wrong_length"
    case Taken = "taken"
    case Invalid = "invalid"
    
    case NotANumber = "not_a_number"
}
typealias ValidationErrors = Errors

extension ActiveRecord {
    struct Errors {
        
        var model: ActiveRecord
        
        var attributes = Dictionary<String, ValidationErrors>()
        public func add(attribute: String, message: ValidationErrors) {
            self.attributes[attribute] = message
            _messages << "self.model"message.rawValue
        }
        private var _messages = Array<String>()
        public var messages: [String] {
            return base + _messages
        }
        
        public var base = Array<String>()
        
        
        public func contains(attribute: String) -> Bool {
            return self.attributes[attribute] != nil
        }
        
        public init(model: ActiveRecord) {
            self.model = model
        }
    }

}