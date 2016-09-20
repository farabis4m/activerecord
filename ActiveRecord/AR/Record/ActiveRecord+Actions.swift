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
            try type(of: first).destroy(self.map({ $0 as! ActiveRecord }))
        }
    }
}

extension ActiveRecord {
    public func update(_ attributes: [String: Any]? = nil) throws -> Bool {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(type(of: self), action: .update).execute(self)
            try self.before(.update)
            // TODO: Add updatable specific attributes
            try UpdateManager(record: self).execute()
            ActiveCallbackStorage.afterStorage.get(type(of: self), action: .update).execute(self)
            try self.after(.update)
        }
        return false
    }
    
    public func update(_ attribute: String, value: Any) throws -> Bool {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(type(of: self), action: .update).execute(self)
            try self.before(.update)
            // TODO: Add updatable specific attributes
            try UpdateManager(record: self).execute()
            ActiveCallbackStorage.afterStorage.get(type(of: self), action: .update).execute(self)
            try self.after(.update)
        }
        return false
    }
    
    public func destroy() throws {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(type(of: self), action: .destroy).execute(self)
            try self.before(.destroy)
            let deleteManager = try DeleteManager(record: self).execute()
            ActiveCallbackStorage.afterStorage.get(type(of: self), action: .destroy).execute(self)
            try self.after(.destroy)
        }
    }
    
    public static func destroy(scope identifier: DatabaseRepresentable) throws {
        // Destroy an item without callbacks
    }
    
    public static func destroy(_ records: [ActiveRecord]) throws {
        if let first = records.first {
            let tableName = type(of: first).tableName
            let structure = Adapter.current.structure(tableName)
            let values = records.map({ "\(($0.attributes[structure.PKColumn.name] as! DatabaseRepresentable).dbValue)" }).joined(separator: ", ")
            try Adapter.current.connection.execute("DELETE FROM \(tableName) WHERE \(structure.PKColumn.name) IN (\(values));")
        }
    }
    
    public static func destroy(_ record: ActiveRecord) throws {
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self, action: .destroy).execute(record)
            try self.destroy([record])
            ActiveCallbackStorage.afterStorage.get(self, action: .destroy).execute(record)
        }
    }
    
    public func save() throws {
        return try self.save(false)
    }
    
    public static func create(_ attributes: [String : Any], block: ((AnyObject) -> (Void))? = nil) throws -> Self {
        let record = self.init(attributes: attributes)
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self, action: .create).execute(record)
            try record.before(.create)
            try record._save(true)
            ActiveCallbackStorage.afterStorage.get(self, action: .create).execute(record)
            try record.after(.create)
        }
        return record
    }
    
    public static func create() throws -> Self {
        let record = self.init()
        try Transaction.perform {
            ActiveCallbackStorage.beforeStorage.get(self, action: .create).execute(record)
            try record.before(.create)
            try record._save(true)
            ActiveCallbackStorage.afterStorage.get(self, action: .create).execute(record)
            try record.after(.create)
        }
        return record
    }
    
    public static func find(_ identifier: Any) throws -> Self {
        return try self.find(["id" : identifier])
    }
    
    public static func find(_ attributes:[String: Any]) throws -> Self {
        return try ActiveRelation().`where`(attributes).limit(1).execute(true).first!
    }
    
    public static func take(_ count: Int = 1) throws -> [Self] {
        return try ActiveRelation().limit(count).execute()
    }
    
    public static func first() -> Self? {
        return (try? self.take())?.first
    }
    
    public static func `where`(_ attributes: [String: Any]) -> ActiveRelation<Self> {
        return ActiveRelation().`where`(attributes)
    }
    
    public static func includes(_ records: ActiveRecord.Type...) -> ActiveRelation<Self> {
        return ActiveRelation().includes(records)
    }
    
    public static func all() throws -> [Self] {
        return try ActiveRelation().execute()
    }
    
    public func save(_ validate: Bool) throws {
        try Transaction.perform {
            try self._save(validate)
        }
    }
    
    fileprivate func _save(_ validate: Bool) throws {
        ActiveCallbackStorage.beforeStorage.get(type(of: self), action: .save).execute(self)
        try self.before(.save)
        let errors = self.errors
        if validate && !errors.isEmpty {
            SQLLog.error("RecordNotValid not found \(self) \(errors)")
            throw ActiveRecordError.recordNotValid(record: self)
        }
        if self.isNewRecord {
            try InsertManager(record: self).execute()
        } else {
            try UpdateManager(record: self).execute()
        }
        self.timeline.reset(self.attributes)
        ActiveCallbackStorage.afterStorage.get(type(of: self), action: .save).execute(self)
        try self.after(.save)
    }
    
    var isNewRecord: Bool {
        if let id = self.attributes["id"], let record = try? type(of: self).find(["id" : id]) {
            return false
        }
        return true
    }
    
    var isDirty: Bool {
        return !self.dirty.isEmpty
    }
}
