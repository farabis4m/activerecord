//
//  ActiveRecord.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import InflectorKit

enum ActiveRecordError: ErrorType {
    case RecordNotValid(record: ActiveRecord)
    case AttributeMissing(record: ActiveRecord, name: String)
    case InvalidAttributeType(record: ActiveRecord, name: String, expectedType: String)
}

protocol ActiveRecord {
    var id: Any? {set get}
    init()
    init(attributes: [String:Any?])

    func setAttrbiutes(attributes: [String: Any?])
    func getAttributes() -> [String: Any?]
    
//    func getTypes() -> [String: ]
    
    static var tableName: String { get }
    static var resourceName: String { get }
    static func acceptedNestedAttributes() -> [String]
}

extension ActiveRecord {
    static var tableName: String {
        var className = "\(self.dynamicType)"
        if let typeRange = className.rangeOfString(".Type") {
            className.replaceRange(typeRange, with: "")
        }
        return className.lowercaseString.pluralizedString()
    }
    
    static var resourceName: String {
        var className = "\(self.dynamicType)"
        if let typeRange = className.rangeOfString(".Type") {
            className.replaceRange(typeRange, with: "")
        }
        return className.lowercaseString
    }
    
    static func acceptedNestedAttributes() -> [String] { return [] }
}


extension ActiveRecord {
    var isValid: Bool {
        return self.validate()
    }
    
    func validate() -> Bool {
        return true
    }
}

extension ActiveRecord {
    func update(attributes: [String: Any?]) throws -> Bool {
        // TODO: get diff between model snapshot and passed attributes
        try ActiveRelation(model: self).update(attributes)
        // TODO: update model attributes
        return false
    }
    
    func update(attribute: String, value: Any) throws -> Bool {
        try ActiveRelation(model: self).update([attribute: value])
        // TODO: update model attributes
        return false
    }
    
    func destroy() throws -> Bool {
        return false
    }
    
    func save() throws -> Bool {
        return try self.save(false)
    }
    
    static func create(attributes: [String : Any?], block: ((AnyObject) -> (Void))? = nil) throws -> Self {
        let record = self.init(attributes: attributes)
        try record.save(true)
        return record;
    }
    
    static func find(identifier:Any) throws -> Self? {
        return try take().first
    }
    
    static func find(attributes:[String:Any]) throws -> Self? {
        return try ActiveRelation().`where`(attributes).execute().first
    }
    
    static func take(count: Int = 1) throws -> [Self] {
        return try ActiveRelation().limit(count).execute()
    }
    
    static func `where`(attributes: [String:Any]) -> ActiveRelation<Self> {
        return ActiveRelation().`where`(attributes)
    }
    
    static func all() throws -> [Self] {
        return try ActiveRelation().execute()
    }
    
    func save(validate: Bool = false) throws -> Bool {
        if validate && !self.isValid {
            throw ActiveRecordError.RecordNotValid(record: self)
        }
        let result = try ActiveRelation(model: self).update()
        ActiveSnapshotStorage.sharedInstance.set(self)
        return result
    }
}

extension ActiveRecord {
    init(attributes: [String:Any?]) {
        self.init()
        self.attributes = attributes
    }
}

extension ActiveRecord {
    var attributes: [String: Any?] {
        get {
            return getAttributes()
        }
        set {
            self.setAttrbiutes(newValue)
            ActiveSnapshotStorage.sharedInstance.set(self)
        }
    }
    func setAttrbiutes(attributes: [String: Any?]) {}
    func getAttributes() -> [String: Any?] {
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