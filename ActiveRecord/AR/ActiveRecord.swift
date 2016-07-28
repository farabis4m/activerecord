//
//  ActiveRecord.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

public enum ActiveRecordError: ErrorType {
    case RecordNotValid(record: ActiveRecord)
    case RecordNotFound(attributes: [String: Any])
    case AttributeMissing(record: ActiveRecord, name: String)
    case InvalidAttributeType(record: ActiveRecord, name: String, expectedType: String)
    case ParametersMissing(record: ActiveRecord)
}

public protocol ActiveRecord: class, Transformable, DatabaseRepresetable {
    var id: Any! { set get }
    init()
    init(attributes: [String:Any?])
    
    func setAttrbiutes(attributes: [String: Any])
    func getAttributes() -> [String: Any]
    
    static var tableName: String { get }
    static var resourceName1: String { get }
    static func acceptedNestedAttributes() -> [String]
    
    // Validators
    func validate(action: Action) -> Errors
    func validators(action: Action) -> [String: Validator]
    
    // Callbackcs
    func before(action: ActiveRecrodAction)
    func after(action: ActiveRecrodAction)
    
    static func before(action: ActiveRecrodAction, callback: ActiveRecordCallback)
    static func after(action: ActiveRecrodAction, callback: ActiveRecordCallback)
}

extension ActiveRecord {
    // Returns sanitized id
    // DB will not allow to insert a record with nil PK
    var identifier: Any {
        return self.id ?? Optional<Int>()
    }
}

extension ActiveRecord {
    // TODO: Don't have any other opportunities to compare hashes
    var hashValue: DatabaseRepresetable? {
        return self.id as? DatabaseRepresetable
    }
}

// Defaults
extension ActiveRecord {
    // Nested attributes
    public static func acceptedNestedAttributes() -> [String] { return [] }
    // Transformable
    public static func transformers() -> [String: Transformer] { return [:] }
}

extension ActiveRecord {
    public init(attributes: [String: Any]) {
        self.init()
        var merged = self.defaultValues
        merged.merge(attributes)
        self.setAttrbiutes(merged)
        self.after(.Initialize)
    }
}

public func ==(lhs: DatabaseRepresetable?, rhs: DatabaseRepresetable?) -> Bool {
    if let left = lhs {
        if let right = rhs {
            if left.rawType != right.rawType { return false }
            switch left.rawType {
            case "String": return (left as! String) == (right as! String)
            case "Int": return (left as! Int) == (right as! Int)
            case "Float": return (left as! Float) == (right as! Float)
            case "Bool": return (left as! Bool) == (right as! Bool)
            case "ActiveRecord": return (left as? ActiveRecord) == (right as? ActiveRecord)
            default: return false
            }
        }
        return false
    } else if let right = rhs {
        return false
    }
    return true
}

public func ==(l: ActiveRecord?, r: ActiveRecord?) -> Bool {
    return l?.hashValue == r?.hashValue
}

public enum ActiveRecrodAction: Int, Hashable {
    case Initialize
    case Create
    case Update
    case Destroy
    case Save
    
    public var hashValue: Int {
        return self.rawValue
    }
}

public enum Action {
    case Create
    case Update
    case Delete
}
