//
//  ActiveRecord+Actions.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation
import ApplicationSupport
import SwiftyBeaver

public extension Array where Element: ActiveRecord {
    func destroyAll() throws {
        if let first = self.first {
            try first.dynamicType.destroy(self.map({ $0 as! ActiveRecord }))
        }
    }
}

extension ActiveRecord {
    public func update(attributes: [String: Any]? = nil) throws -> Bool {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Update).execute(self)
            try self.before(.Update)
            // TODO: Add updatable specific attributes
            try UpdateManager(record: self).execute()
            ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Update).execute(self)
            try self.after(.Update)
        }
        return false
    }
    
    @warn_unused_result
    public func update(attribute: String, value: Any) throws -> Bool {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Update).execute(self)
            try self.before(.Update)
            // TODO: Add updatable specific attributes
            try UpdateManager(record: self).execute()
            ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Update).execute(self)
            try self.after(.Update)
        }
        return false
    }
    
    @warn_unused_result
    public func destroy() throws {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Destroy).execute(self)
            try self.before(.Destroy)
            let deleteManager = try DeleteManager(record: self).execute()
            ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Destroy).execute(self)
            try self.after(.Destroy)
        }
    }
    
    @warn_unused_result
    public static func destroy(scope identifier: DatabaseRepresentable) throws {
        // Destroy an item without callbacks
    }
    
    public static func destroy(records: [ActiveRecord]) throws {
        if let first = records.first {
            let tableName = first.dynamicType.tableName
            let structure = Adapter.current.structure(tableName)
            let values = records.map({ "\(($0.attributes[structure.PKColumn.name] as! DatabaseRepresentable).dbValue)" }).joinWithSeparator(", ")
            try Adapter.current.connection.execute("DELETE FROM \(tableName) WHERE \(structure.PKColumn.name) IN (\(values));")
        }
    }
    
    public static func destroy(record: ActiveRecord) throws {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self, action: .Destroy).execute(record)
            try self.destroy([record])
            ActiveCallbackStorage.afterStorage.get(self, action: .Destroy).execute(record)
        }
    }
    
    public func save() throws {
        return try self.save(false)
    }
    
    public static func create(attributes: [String : Any], block: ((AnyObject) -> (Void))? = nil) throws -> Self {
        let record = self.init(attributes: attributes)
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self, action: .Create).execute(record)
            try record.before(.Create)
            try record.save(true)
            ActiveCallbackStorage.afterStorage.get(self, action: .Create).execute(record)
            try record.after(.Create)
        }
        return record
    }
    
    public static func create() throws -> Self {
        let record = self.init()
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self, action: .Create).execute(record)
            try record.before(.Create)
            try record.save(true)
            ActiveCallbackStorage.afterStorage.get(self, action: .Create).execute(record)
            try record.after(.Create)
        }
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
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self.dynamicType, action: .Save).execute(self)
            try self.before(.Save)
            let errors = self.errors
            if validate && !errors.isEmpty {
                SQLLog.error("RecordNotValid not found \(self) \(errors)")
                throw ActiveRecordError.RecordNotValid(record: self)
            }
            if self.isNewRecord {
                try InsertManager(record: self).execute()
            } else {
                try UpdateManager(record: self).execute()
            }
            self.timeline.reset(self.attributes)
            ActiveCallbackStorage.afterStorage.get(self.dynamicType, action: .Save).execute(self)
            try self.after(.Save)
        }
    }
    
    var isNewRecord: Bool {
        if let id = self.attributes["id"], let record = try? self.dynamicType.find(["id" : id]) {
            return false
        }
        return true
    }
    
    var isDirty: Bool {
        return !self.dirty.isEmpty
    }
}