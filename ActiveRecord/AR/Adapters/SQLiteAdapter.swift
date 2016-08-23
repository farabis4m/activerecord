//
//  SqliteAdapter.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/1/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

public class SQLiteAdapter: Adapter {
    
    override var columnTypes: [String : Table.Column.DBType] {
        return ["text" : .String,
                "int"  : .Int,
                "date" : .Date,
                "real" : .Decimal,
                "blob" : .Raw]
    }
    
    override var persistedColumnTypes: [Table.Column.DBType: String] {
        return [.Int : "INTEGER",
                .Decimal : "REAL",
                .Date : "DATE",
                .String : "TEXT",
                .Bool : "INT",
                .Raw : "BLOB"]
    }
    
    private var reversedColumnTypes: [String: Table.Column.DBType] {
        return ["INTEGER": .Int,
                "REAL": .Decimal,
                "DATE": .Date,
                "TEXT": .String,
                "INT": .Bool,
                "BLOB": .Raw]
    }
    
//    override public func tables() -> Array<String> {
//        do {
//            let result = try self.connection.execute_query("SELECT name FROM sqlite_master WHERE (type = 'table' OR type == 'view' AND NOT name = 'sqlite_sequence')")
//            return result.hashes.map({ $0["name"] as! String })
//        } catch {
//            print("\(error)")
//        }
//        return super.tables()
//    }
    
    override public func structure(tableName: String) -> Table {
        let table = super.structure(tableName)
        do {
            let result = try self.connection.execute_query("PRAGMA table_info(\(table.name.quoted))")
            for row in result.hashes {
                let columnName = row["name"] as! String
                let column = Table.Column(name: columnName, table: tableName) { column in
                    column.`default` = row["dfltValue"]
                    column.PK = row["pk"] as? Int == 1
                    column.nullable = row["notnull"] as? Int == 1
                    column.type = self.reversedColumnTypes[row["type"] as! String]
                }
                table.columns << column
            }
            return table
        } catch {
            print("\(error)")
        }
        return table
    }
    
    //MARK: -
    
    public override func create<T: DBObject>(object: T) throws {
        var SQL: String = ""
        if let table = object as? Table {
            SQL = Table.Action.Create.clause(table.name) + "(" + table.columns.map({ $0.description }).joinWithSeparator(", ") + ")"
        } else if let column = object as? Table.Column {
            SQL = Table.Action.Alter.clause(column.table!) + " ADD COLUMN " + column.description
        } else if object is Function {
            // TODO: Add implementation
        }
        try self.connection.execute(SQL)
    }
    
    public override func rename<T: DBObject>(object: T, name: String) throws {
        var SQL: String = ""
        if let table = object as? Table {
            SQL = Table.Action.Alter.clause(table.name) + " RENAME TO " + name;
        } else if let column = object as? Table.Column {
            SQL = Table.Action.Alter.clause(column.table!) + "RENAME COLUMN " + column.name + " TO " + name;
        } else if object is Function {
            // TODO: Add implementation
        }
        try self.connection.execute(SQL)
    }
    
    public override func drop<T: DBObject>(object: T) throws {
        var SQL: String = ""
        if let table = object as? Table {
            SQL = Table.Action.Drop.clause(table.name)
        } else if let column = object as? Table.Column {
            SQL = Table.Action.Alter.clause(column.name) + " DROP COLUMN " + column.name
        } else if object is Function {
            // TODO: Add implementation
        }
        try self.connection.execute(SQL)
    }
    
    public override func exists<T: DBObject>(object: T) throws -> Bool {
        if let table = object as? Table {
            return self.tables.map({ $0.name }).contains(table.name)
        } else if let column = object as? Table.Column {
            return self.tables.filter({ $0.name == column.table }).filter({ !$0.columns.filter({ $0.name == column.name }).isEmpty }).isEmpty
        } else if object is Function {
            // TODO: Add implementation for function
        }
        return false
    }
    
    public override func reference(to: String, on: String, options: [String: Any]? = nil) throws {
        let columnName = options?["column"] as? String ?? "\(on.singularized)_id"
        let column = Table.Column(name: columnName, type: .Int, table: to)
        column.foreignTable = Adapter.current.tables.find({ $0.name == on })
        try self.create(column)
    }
    
}
