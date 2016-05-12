//
//  Migration.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import InflectorKit

public func <<<T> (inout left: [T], right: T) -> [T] {
    left.append(right)
    return left
}

public protocol Migration {
    var timestamp: Int { get }
    func up()
    func down()
}

extension Migration {
    var id: String { return "\(self.dynamicType)" }
    var timestamp: Int { return 0 }
    
    var adapter: Adapter { return Adapter.current }
    
    func up() {}
    func down() {}
}

public let foreignKey = "foreignKey"
public let column = "column"

extension Migration {
    public func create<T: DBObject>(object: T, block: ((T) -> (Void))? = nil) {
        block?(object)
        var SQL: String = ""
        if let table = object as? Table {
            SQL = Table.Action.Create.clause(table.name) + "(" + table.columns.map({ $0.description }).joinWithSeparator(", ") + ")"
            MigrationsController.sharedInstance.tables << table
        } else if let column = object as? Table.Column {
            SQL = Table.Action.Alter.clause(column.table!) + " ADD COLUMN " + column.description
        } else if object is Function {
            // TODO: Add implementation
        }
        MigrationsController.sharedInstance.check({ try self.adapter.connection.execute(SQL) })
    }
    
    public func rename<T: DBObject>(object: T, name: String) {
        var SQL: String = ""
        if let table = object as? Table {
            SQL = Table.Action.Alter.clause(table.name) + " RENAME TO " + name;
        } else if let column = object as? Table.Column {
            SQL = Table.Action.Alter.clause(column.table!) + "RENAME COLUMN " + column.name + " TO " + name;
        } else if object is Function {
            // TODO: Add implementation
        }
        MigrationsController.sharedInstance.check({ try self.adapter.connection.execute(SQL) })
    }
    
    public func drop<T: DBObject>(object: T) {
        var SQL: String = ""
        if let table = object as? Table {
            SQL = Table.Action.Drop.clause(table.name)
        } else if let column = object as? Table.Column {
            SQL = Table.Action.Alter.clause(column.name) + " DROP COLUMN " + column.name
        } else if object is Function {
            // TODO: Add implementation
        }
        MigrationsController.sharedInstance.check({ try self.adapter.connection.execute(SQL) })
    }
    
    public func exists<T: DBObject>(object: T) -> Bool {
        if let table = object as? Table {
            return self.adapter.tables().contains(table.name)
        } else if let column = object as? Table.Column {
            return self.adapter.structure(column.table!).keys.contains(column.name)
        } else if object is Function {
            // TODO: Add implementation for function
        }
        return false
    }
    
    public func reference(to: String, on: String, options: [String: Any]? = nil) {
        let columnName = options?["column"] as? String ?? "\(on.singularizedString())_id"
        self.create(Table.Column(name: columnName, type: .Int, table: to))
        if let foreignKey = options?["foreignKey"] as? Bool where foreignKey == true && adapter is SQLiteAdapter == false {
            let SQL = "\(Table.Action.Alter.clause(to)) ADD CONSTRAINT \(to)_\(columnName) FOREIGN KEY (\(columnName)) REFERENCES \(on)(id);"
            MigrationsController.sharedInstance.check({ try self.adapter.connection.execute(SQL) })
        }
    }
}