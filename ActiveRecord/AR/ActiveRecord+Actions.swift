//
//  ActiveRecord+Actions.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

extension ActiveRecord {
    public func update(attributes: [String: Any]? = nil) throws -> Bool {
        ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Update).execute(self)
        self.before(.Update)
        // TODO: Add updatable specific attributes
        try UpdateManager(record: self).execute()
        ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Update).execute(self)
        self.after(.Update)
        return false
    }
    
    public func update(attribute: String, value: Any) throws -> Bool {
        ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Update).execute(self)
        self.before(.Update)
        // TODO: Add updatable specific attributes
        try UpdateManager(record: self).execute()
        ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Update).execute(self)
        self.after(.Update)
        return false
    }
    
    public func destroy() throws {
        ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Destroy).execute(self)
        self.before(.Destroy)
        let deleteManager = try DeleteManager(record: self).execute()
        ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Destroy).execute(self)
        self.after(.Destroy)
    }
    
    public static func destroy(scope identifier: Any) throws {
        let record = self.init()
        record.id = identifier
        ActiveCallbackStorage.beforeStorage.get(self, action: .Destroy).execute(record)
        try self.destroy(record)
        ActiveCallbackStorage.afterStorage.get(self, action: .Destroy).execute(record)
    }
    
    public static func destroy(records: [ActiveRecord]) throws {
        if let first = records.first {
            let tableName = first.dynamicType.tableName
            let structure = Adapter.current.structure(tableName)
            if let PK = structure.values.filter({ return $0.PK }).first {
                let values = records.map({ "\(($0.attributes[PK.name] as! DatabaseRepresetable).dbValue)" }).joinWithSeparator(", ")
                try Adapter.current.connection.execute("DELETE FROM \(tableName) WHERE \(PK.name) IN (\(values));")
            }
        }
    }
    
    public static func destroy(record: ActiveRecord) throws {
        ActiveCallbackStorage.beforeStorage.get(self, action: .Destroy).execute(record)
        try self.destroy([record])
        ActiveCallbackStorage.afterStorage.get(self, action: .Destroy).execute(record)
    }
    
    public func save() throws {
        return try self.save(false)
    }
    
    public static func create(attributes: [String : Any], block: ((AnyObject) -> (Void))? = nil) throws -> Self {
        let record = self.init(attributes: attributes)
        ActiveCallbackStorage.beforeStorage.get(self, action: .Create).execute(record)
        record.before(.Create)
        try record.save(true)
        ActiveCallbackStorage.afterStorage.get(self, action: .Create).execute(record)
        record.after(.Create)
        return record
    }
    
    public static func create() throws -> Self {
        let record = self.init()
        ActiveCallbackStorage.beforeStorage.get(self, action: .Create).execute(record)
        record.before(.Create)
        try record.save(true)
        ActiveCallbackStorage.afterStorage.get(self, action: .Create).execute(record)
        record.after(.Create)
        return record
    }
    
    public static func find(identifier: Any) throws -> Self {
        return try self.find(["id" : identifier])
    }
    
    public static func find(attributes:[String: Any]) throws -> Self {
        return try ActiveRelation().`where`(attributes).limit(1).execute(true).first!
    }
    
    public static func take(count: Int = 1) throws -> [Self] {
        return try ActiveRelation().limit(count).execute()
    }
    
    public static func first() -> Self? {
        return (try? self.take())?.first
    }
    
    public static func `where`(attributes: [String: Any]) -> ActiveRelation<Self> {
        return ActiveRelation().`where`(attributes)
    }
    
    public static func includes(records: ActiveRecord.Type...) -> ActiveRelation<Self> {
        return ActiveRelation().includes(records)
    }
    
    public static func all() throws -> [Self] {
        return try ActiveRelation().execute()
    }
    
    public func save(validate: Bool) throws {
        ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Save).execute(self)
        self.before(.Save)
        if validate && !self.isValid {
            throw ActiveRecordError.RecordNotValid(record: self)
        }
        if self.isNewRecord {
            try InsertManager(record: self).execute()
        } else {
            try UpdateManager(record: self).execute()
        }
        ActiveSnapshotStorage.sharedInstance.set(self)
        ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Save).execute(self)
        self.after(.Save)
    }
    
    var isNewRecord: Bool {
        if let id = self.id, let record = try? self.dynamicType.find(["id" : id]) {
            return false
        }
        return true
    }
    
    var isDirty: Bool {
        return !self.dirty.isEmpty
    }
}