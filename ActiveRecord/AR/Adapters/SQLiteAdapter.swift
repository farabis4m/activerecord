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
                "blob" : .Raw,
                "double" : .Double]
    }
    
    override var persistedColumnTypes: [Table.Column.DBType: String] {
        return [.Int : "INTEGER",
                .Decimal : "REAL",
                .Date : "DATE",
                .String : "TEXT",
                .Bool : "INT",
                .Raw : "BLOB",
                .Double : "DOUBLE"]
    }
    
    private var reversedColumnTypes: [String: Table.Column.DBType] {
        return ["INTEGER": .Int,
                "REAL": .Decimal,
                "DATE": .Date,
                "TEXT": .String,
                "INT": .Bool,
                "BLOB": .Raw,
                "DOUBLE" : .Double]
    }
    

    enum SQLite {
        enum Table {
            enum Action: SQLConvertible {
                case Create(DB.Table)
                case Drop(DB.Table)
                case Alter(DB.Table)
                case Rename(DB.Table, String)
                
                var clause: String {
                    switch self {
                    case .Create(let table):
                        return "CREATE TABLE"
                    case .Drop(let table):
                        return "DROP TABLE"
                    case .Alter, .Rename:
                        return "ALTER TABLE"
                    default: return ""
                    }
                }
                
                var SQL: String {
                    switch self {
                    case .Create(let table):
                        let columns = table.columns.map({ $0.description }).joinWithSeparator(", ")
                        return self.clause + " " + table.name.untrim + columns.embrace
                    case .Rename(let table, let name):
                        return self.clause + " " + table.name.untrim + "RENAME TO \(name)"
                    case .Alter(let table):
                        return self.clause + " " + table.name
                    case .Drop(let table):
                        return self.clause + " " + table.name
                    default:
                        return ""
                    }
                }
            }
            
            enum Column {
                enum Action: SQLConvertible {
                    case Create(DB.Table.Column)
                    case Drop(DB.Table.Column)
                    case Alter(DB.Table)
                    case Rename(DB.Table.Column, String)
                    
                    var SQL: String {
                        switch self {
                        case .Create(let column):
                            return  Table.Action.Alter(column.table!).SQL + " ADD COLUMN " + column.description + ";"
                        case .Drop(let column):
                            return  Table.Action.Alter(column.table!).SQL + " DROP COLUMN " + column.name + ";"
                        case .Rename(let column, let name):
                            return  Table.Action.Alter(column.table!).SQL + " RENAME COLUMN " + name + ";"
                        default:
                            return ""
                        }
                    }
                }
            }
        }
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
        guard let table = self.tables.find({ $0.name == tableName }) else {
            let table = super.structure(tableName)
            do {
                let result = try self.connection.execute_query("PRAGMA table_info(\(table.name.quoted))")
                for row in result.hashes {
                    let columnName = row["name"] as! String
                    let column = Table.Column(name: columnName, table: table) { column in
                        column.`default` = row["dfltValue"]
                        column.PK = row["pk"] as? Int == 1
                        column.nullable = row["notnull"] as? Int == 1
                        column.type = self.reversedColumnTypes[row["type"] as! String]
                    }
                    table.columns << column
                }
                self.tables << table
                return table
            } catch {
                print("\(error)")
            }
            return table
        }
        return table
    }
    
    //MARK: -
    
    public override func create<T: DBObject>(object: T) throws {
        if let table = object as? Table {
            try self.connection.execute(SQLite.Table.Action.Create(table).SQL)
            self.tables << table
        } else if let column = object as? Column {
            try self.connection.execute(SQLite.Table.Column.Action.Create(column).SQL)
        }
    }
    
    public override func rename<T: DBObject>(object: T, name: String) throws {
        if let table = object as? Table {
            try self.connection.execute(SQLite.Table.Action.Rename(table, name).SQL)
            table.name = name
        } else if let column = object as? Column {
            try self.connection.execute(SQLite.Table.Column.Action.Rename(column, name).SQL)
            column.name = name
        }
    }
    
    public override func drop<T: DBObject>(object: T) throws {
        if let table = object as? Table {
            try self.connection.execute(SQLite.Table.Action.Drop(table).SQL)
            if let index = self.tables.indexOf({ $0.name == table.name }) {
                self.tables.removeAtIndex(index)
            }
        } else if let column = object as? Column {
            try self.connection.execute(SQLite.Table.Column.Action.Drop(column).SQL)
            if let index = column.table?.columns.indexOf({ $0.name == column.name }) {
                column.table?.columns.removeAtIndex(index)
            }
        }
    }
    
    public override func exists<T: DBObject>(object: T) -> Bool {
        if let table = object as? Table {
            if let localTable = self.tables.find({ $0.name == table.name }) {
                return true
            }
            do {
                let result = try self.connection.execute_query("SELECT name FROM sqlite_master WHERE type='table' AND name='\(table.name)';")
                return !result.hashes.isEmpty
            } catch {}
            return false
        } else if let column = object as? Column {
            return column.table?.columns.find({ $0.name == column.name }) != nil
        }
        return false
    }
    
    public override func reference(to: String, on: String, options: [String: Any]? = nil) throws {
        let columnName = options?["column"] as? String ?? "\(on.singularized)_id"
        let table = Adapter.current.tables.find({ $0.name == to })!
        let column = Table.Column(name: columnName, type: .Int, table: table)
        try self.create(column)
    }
    
}
