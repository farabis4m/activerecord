//
//  ActiveRecord.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import InflectorKit

public enum ActiveRecordError: ErrorType {
    case RecordNotValid(record: ActiveRecord)
    case RecordNotFound(attributes: [String: Any])
    case AttributeMissing(record: ActiveRecord, name: String)
    case InvalidAttributeType(record: ActiveRecord, name: String, expectedType: String)
    case ParametersMissing(record: ActiveRecord)
}

// TODO: Find a way make it as Hashable
public protocol AnyType: Any {
    var dbValue: AnyType { get }
    var rawType: String { get }
    func ==(lhs: AnyType?, rhs: AnyType?) -> Bool
}

extension AnyType {
    public var rawType: String {
        return "\(self)"
    }
    
    public var dbValue: AnyType {
        return self
    }
}

public func ==(lhs: AnyType?, rhs: AnyType?) -> Bool {
    if let left = lhs {
        if let right = rhs {
            if left.rawType != right.rawType { return false }
            switch left.rawType {
            case "String": return (left as! String) == (right as! String)
            case "Int": return (left as! Int) == (right as! Int)
            case "Float": return (left as! Float) == (right as! Float)
            case "ActiveRecord": return (left as! ActiveRecord).hashValue == (right as! ActiveRecord).hashValue
            default: return false
            }
        }
        return false
    }
    return true
}

extension String: AnyType {
    public var rawType: String { return "String" }
    public var dbValue: AnyType { return "'\(self)'" }
}
extension Int: AnyType {
    public var rawType: String { return "Int" }
}
extension Float: AnyType {
    public var rawType: String { return "Float" }
}

public enum ActiveRecrodAction {
    case Initialize
    case Create
    case Update
    case Destroy
    case Save
}

public protocol ActiveRecord: AnyType {
    var id: AnyType? {set get}
    init()
    init(attributes: [String:Any?])
    
    func setAttrbiutes(attributes: [String: Any?])
    func getAttributes() -> [String: Any?]
    
    static var tableName: String { get }
    static var resourceName: String { get }
    static func acceptedNestedAttributes() -> [String]
    
    // Validators
    func validate() -> Errors
    func validators() -> [String: Validator]
    
    // Callbackcs
    func after(action: ActiveRecrodAction)
    func before(action: ActiveRecrodAction)
}

extension ActiveRecord {
    var rawType: String { return "ActiveRecord" }
}

extension ActiveRecord {
    // TODO: Don't have any other opportunities to compare hashes
    var hashValue: AnyType? {
        return self.id
    }
}

extension ActiveRecord {
    public func after(action: ActiveRecrodAction) { }
    public func before(action: ActiveRecrodAction) { }
}

extension ActiveRecord {
    public static var tableName: String {
        var className = "\(self.dynamicType)"
        if let typeRange = className.rangeOfString(".Type") {
            className.replaceRange(typeRange, with: "")
        }
        return className.lowercaseString.pluralizedString()
    }
    
    public static var resourceName: String {
        return self.modelName
    }
    
    public final static var modelName: String {
        var className = "\(self.dynamicType)"
        if let typeRange = className.rangeOfString(".Type") {
            className.replaceRange(typeRange, with: "")
        }
        return className.lowercaseString
    }
    
    public static func acceptedNestedAttributes() -> [String] { return [] }
}


extension ActiveRecord {
    public var errors: Errors { return self.validate() }
    public var isValid: Bool { return self.validate().isEmpty }
    
    public func validate() -> Errors {
        var errors = Errors(model: self)
        let validators = self.validators()
        for (attribute, value) in self.attributes {
            if let validator = validators[attribute] {
                validator.validate(self, attribute: attribute, value: value, errors: &errors)
            }
        }
        return errors
    }
    
    public func validators() -> [String: Validator] {
        return [:]
    }
}

extension ActiveRecord {
    public func update(attributes: [String: Any?]? = nil) throws -> Bool {
        self.before(.Update)
        // TODO: get diff between model snapshot and passed attributes
        try ActiveRelation(model: self).update(attributes)
        // TODO: update model attributes
        self.after(.Update)
        return false
    }
    
    public func update(attribute: String, value: Any) throws -> Bool {
        self.before(.Update)
        try ActiveRelation(model: self).update([attribute: value])
        // TODO: update model attributes
        self.after(.Update)
        return false
    }
    
    public func destroy() throws -> Bool {
        self.before(.Destroy)
        self.after(.Destroy)
        return false
    }
    
    public func save() throws -> Bool {
        return try self.save(false)
    }
    
    public static func create(attributes: [String : Any?], block: ((AnyObject) -> (Void))? = nil) throws -> Self {
        let record = self.init(attributes: attributes)
        record.before(.Create)
        try record.save(true)
        record.after(.Create)
        return record;
    }
    
    public static func find(identifier:Any) throws -> Self {
        return try self.find(["id" : identifier])
    }
    
    public static func find(attributes:[String:Any]) throws -> Self {
        return try ActiveRelation().`where`(attributes).limit(1).execute(true).first!
    }
    
    public static func take(count: Int = 1) throws -> [Self] {
        return try ActiveRelation().limit(count).execute()
    }
    
    public static func `where`(attributes: [String:Any]) -> ActiveRelation<Self> {
        return ActiveRelation().`where`(attributes)
    }
    
    public static func all() throws -> [Self] {
        return try ActiveRelation().execute()
    }
    
    public func save(validate: Bool) throws -> Bool {
        self.before(.Save)
        if validate && !self.isValid {
            throw ActiveRecordError.RecordNotValid(record: self)
        }
        try InsertManager.init(model: self).execute()
        ActiveSnapshotStorage.sharedInstance.set(self)
        self.after(.Save)
        return true
    }
}

extension ActiveRecord {
    public init(attributes: [String:Any?]) {
        self.init()
        self.attributes = attributes
    }
}

extension ActiveRecord {
    public var attributes: [String: Any?] {
        get {
            return getAttributes()
        }
        set {
            self.setAttrbiutes(newValue)
            ActiveSnapshotStorage.sharedInstance.set(self)
        }
    }
    public var dirty: [String: Any?] {
        return ActiveSnapshotStorage.sharedInstance.merge(self)
    }
    public func setAttrbiutes(attributes: [String: Any?]) {}
    public func getAttributes() -> [String: Any?] {
        let reflections = _reflect(self)
        
        var fields = [String: Any?]()
        for index in 0.stride(to: reflections.count, by: 1) {
            let reflection = reflections[index]
            fields[reflection.0] = reflection.1.value
        }
        return fields
    }
}

extension ActiveRecord {
    var fields: String {
        return "\(ActiveSerializer(model: self).fields)"
    }
}