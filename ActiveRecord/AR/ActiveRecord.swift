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

func unwrap(any:Any) -> Any {
    
    let mi = Mirror(reflecting: any)
    if mi.displayStyle != .Optional {
        return any
    }
    
    if mi.children.count == 0 { return any }
    let (_, some) = mi.children.first!
    return some
    
}

public typealias ForwardBlock = ((AnyType) -> Any?)
public typealias BacwardBlock = ((Any) -> AnyType?)
public struct Transformer {
    public var forward: ForwardBlock?
    public var backward: BacwardBlock?
    
    public init(forward: ForwardBlock?, backward: BacwardBlock? = nil) {
        self.forward = forward
        self.backward = backward
    }
    public init(backward: BacwardBlock?) {
        self.backward = backward
    }
}

let NSURLTransformer = Transformer(forward: { (value) -> Any? in
    if let url = value as? String {
        return NSURL(string: url)
    }
    return nil
    }, backward: { (value) -> AnyType? in
        if let url = value as? NSURL {
            return url.absoluteString
        }
        return nil
})

public protocol Transformable {
    static func transformers() -> [String: Transformer]
}

// TODO: Find a way make it as Hashable
public protocol AnyType {
    var dbValue: AnyType { get }
    var rawType: String { get }
    func ==(lhs: AnyType?, rhs: AnyType?) -> Bool
}

extension AnyType {
    public var rawType: String {
        return "\(self)"
    }
    // TODO: Extract as protocol DatabaseRepresatable
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
            case "Bool": return (left as! Bool) == (right as! Bool)
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
extension Bool: AnyType {
    public var rawType: String { return "Bool" }
    public var dbValue: AnyType { return Int(self) }
}

public typealias Date = NSDate
extension Date: AnyType {
    public var rawType: String { return "Date" }
}

public enum ActiveRecrodAction {
    case Initialize
    case Create
    case Update
    case Destroy
    case Save
}

public protocol ActiveRecord: AnyType, Transformable {
    var id: AnyType? {set get}
    init()
    init(attributes: [String:AnyType?])
    
    func setAttrbiutes(attributes: [String: AnyType?])
    func getAttributes() -> [String: AnyType?]
    
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
    public static func transformers() -> [String: Transformer] {
        return [:]
    }
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
    public func update(attributes: [String: AnyType?]? = nil) throws -> Bool {
        self.before(.Update)
        // TODO: Add updatable specific attributes
        try UpdateManager(record: self).execute()
        self.after(.Update)
        return false
    }
    
    public func update(attribute: String, value: AnyType) throws -> Bool {
        self.before(.Update)
        // TODO: Add updatable specific attributes
        try UpdateManager(record: self).execute()
        self.after(.Update)
        return false
    }
    
    public func destroy() throws -> Bool {
        self.before(.Destroy)
        let deleteManager = try DeleteManager(record: self).execute()
        self.after(.Destroy)
        return true
    }
    
    public func save() throws -> Bool {
        return try self.save(false)
    }
    
    public static func create(attributes: [String : AnyType?], block: ((AnyObject) -> (Void))? = nil) throws -> Self {
        let record = self.init(attributes: attributes)
        record.before(.Create)
        try record.save(true)
        record.after(.Create)
        return record;
    }
    
    public static func find(identifier:AnyType) throws -> Self {
        return try self.find(["id" : identifier])
    }
    
    public static func find(attributes:[String:AnyType]) throws -> Self {
        return try ActiveRelation().`where`(attributes).limit(1).execute(true).first!
    }
    
    public static func take(count: Int = 1) throws -> [Self] {
        return try ActiveRelation().limit(count).execute()
    }
    
    public static func first() -> Self? {
        return (try? self.take())?.first
    }
    
    public static func `where`(attributes: [String:AnyType]) -> ActiveRelation<Self> {
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
        try InsertManager.init(record: self).execute()
        ActiveSnapshotStorage.sharedInstance.set(self)
        self.after(.Save)
        return true
    }
}

extension ActiveRecord {
    public init(attributes: [String:AnyType?]) {
        self.init()
        self.setAttrbiutes(attributes)
    }
}

extension ActiveRecord {
    public var attributes: [String: AnyType?] {
        get {
            return getAttributes()
        }
        set {
            self.setAttrbiutes(newValue)
            ActiveSnapshotStorage.sharedInstance.set(self)
        }
    }
    public var dirty: [String: AnyType?] {
        let snapshot = ActiveSnapshotStorage.sharedInstance.merge(self)
        var dirty = Dictionary<String, AnyType?>()
        let attributes = self.attributes
        for (k, v) in attributes {
            let snapshotEmpty = snapshot[k] == nil
            let valueEmpty = v == nil
            print("\(k): \(snapshot[k]) v: \(v) se: \(snapshotEmpty) ve: \(valueEmpty)")
            if let value = snapshot[k] where (value == v) == false {
                dirty[k] = v
            } else {
                // TODO: Simplify it
                if let sn = snapshot[k], let ssn = sn {
                } else {
                    if !valueEmpty {
                        dirty[k] = v
                    }
                }
            }
        }
        return dirty
    }
    public func setAttrbiutes(attributes: [String: AnyType?]) {}
    public func getAttributes() -> [String: AnyType?] {
        let reflections = _reflect(self)
        var fields = [String: AnyType?]()
        let transformers = self.dynamicType.transformers()
        for index in 0.stride(to: reflections.count, by: 1) {
            let reflection = reflections[index]
            var result: AnyType?
            var value = unwrap(reflection.1.value)
            if let url = value as? NSURL {
                result = NSURLTransformer.backward?(value)
            } else {
                if let transformer = transformers[reflection.0] {
                    result = transformer.backward?(value)
                } else {
                    result = value as? AnyType
                }
            }
            fields[reflection.0] = result
        }
        return fields
    }
}

extension ActiveRecord {
    var fields: String {
        return "\(ActiveSerializer(model: self).fields)"
    }
}