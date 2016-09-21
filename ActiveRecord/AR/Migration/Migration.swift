//
//  Migration.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

public protocol Migration {
    var timestamp: Int { get }
    func up() throws
    func down() throws
}

extension Migration {
    var id: String { return "\(type(of: self))" }
    var timestamp: Int { return 0 }
    
    var adapter: Adapter { return Adapter.current }
    
    func up() throws {}
    func down() throws {}
}

public let foreignKey = "foreignKey"
public let column = "column"

extension Migration {
    public func create<T: DBObject>(_ object: T, block: ((T) -> (Void))? = nil) throws {
        block?(object)
        if MigrationsController.sharedInstance.enabled {
            try self.adapter.create(object)
        } else {
            _create(object)
        }
    }
    
    public func rename<T: DBObject>(_ object: T, name: String) throws {
        if MigrationsController.sharedInstance.enabled {
            try self.adapter.rename(object, name: name)
        } else {
            _rename(object, name: name)
        }
    }
    
    public func drop<T: DBObject>(_ object: T) throws {
        if MigrationsController.sharedInstance.enabled {
            try self.adapter.drop(object)
        } else {
            _drop(object)
        }
    }
    
    public func exists<T: DBObject>(_ object: T) -> Bool {
        return (try? self.adapter.exists(object)) ?? false
    }
    
    public func reference(_ to: String, on: String, options: [String: Any]? = nil) throws {
        if MigrationsController.sharedInstance.enabled {
            try self.adapter.reference(to, on: on, options: options)
        } else {
            _reference(to, on: on, options: options)
        }
        
    }
    
    func _create<T: DBObject>(_ object: T) {
        if let table = object as? Table {
            Adapter.current.tables << table
        } else if let column = object as? Column {
            column.table!.columns << column
        }
    }
    
    func _rename<T: DBObject>(_ object: T, name: String) {
        if let table = object as? Table {
            table.name = name
        } else if let column = object as? Column {
            column.name = name
        }
    }
    
    func _drop<T: DBObject>(_ object: T) {
        if let table = object as? Table {
            if let index = Adapter.current.tables.index(where: { $0.name == table.name }) {
                Adapter.current.tables.remove(at: index)
            }
        } else if let column = object as? Column {
            if let index = column.table?.columns.index(where: { $0.name == column.name }) {
                column.table?.columns.remove(at: index)
            }
        }
    }
    
    func _reference(_ to: String, on: String, options: [String: Any]? = nil) {
        let columnName = options?["column"] as? String ?? "\(on.singularized)_id"
        let table = Adapter.current.tables.find(predicate: { $0.name == to })!
        let column = Table.Column(name: columnName, type: .Int, table: table)
        _create(column)
    }
}
