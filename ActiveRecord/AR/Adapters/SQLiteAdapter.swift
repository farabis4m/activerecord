//
//  SqliteAdapter.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/1/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

open class SQLiteAdapter: Adapter {
    
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
    
    fileprivate var reversedColumnTypes: [String: Table.Column.DBType] {
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
                case create(DB.Table)
                case drop(DB.Table)
                case alter(DB.Table)
                case rename(DB.Table, String)
                
                var clause: String {
                    switch self {
                    case .create(_):
                        return "CREATE TABLE"
                    case .drop(_):
                        return "DROP TABLE"
                    case .alter, .rename:
                        return "ALTER TABLE"
                    }
                }
                
                var SQL: String {
                    switch self {
                    case .create(let table):
                        let columns = table.columns.map({ $0.description }).joined(separator: ", ")
                        return self.clause + " " + table.name.untrim + columns.embrace
                    case .rename(let table, let name):
                        return self.clause + " " + table.name.untrim + "RENAME TO \(name)"
                    case .alter(let table):
                        return self.clause + " " + table.name
                    case .drop(let table):
                        return self.clause + " " + table.name
                    }
                }
            }
            
            enum Column {
                enum Action: SQLConvertible {
                    case create(DB.Table.Column)
                    case drop(DB.Table.Column)
                    case alter(DB.Table)
                    case rename(DB.Table.Column, String)
                    
                    var SQL: String {
                        switch self {
                        case .create(let column):
                            return  Table.Action.alter(column.table!).SQL + " ADD COLUMN " + column.description + ";"
                        case .drop(let column):
                            return  Table.Action.alter(column.table!).SQL + " DROP COLUMN " + column.name + ";"
                        case .rename(let column, let name):
                            return  Table.Action.alter(column.table!).SQL + " RENAME COLUMN " + name + ";"
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
    
    override open func structure(_ tableName: String) -> Table {
        guard let table = self.tables.find(predicate: { $0.name == tableName }) else {
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
    
    open override func create<T: DBObject>(_ object: T) throws {
        if let table = object as? Table {
            try self.connection.execute(SQLite.Table.Action.create(table).SQL)
            self.tables << table
        } else if let column = object as? Column {
            try self.connection.execute(SQLite.Table.Column.Action.create(column).SQL)
            column.table?.columns.append(column)
        }
    }
    
    open override func rename<T: DBObject>(_ object: T, name: String) throws {
        if let table = object as? Table {
            try self.connection.execute(SQLite.Table.Action.rename(table, name).SQL)
            table.name = name
        } else if let column = object as? Column {
            try self.connection.execute(SQLite.Table.Column.Action.rename(column, name).SQL)
            column.name = name
        }
    }
    
    open override func drop<T: DBObject>(_ object: T) throws {
        if let table = object as? Table {
            try self.connection.execute(SQLite.Table.Action.drop(table).SQL)
            if let index = self.tables.index(where: { $0.name == table.name }) {
                self.tables.remove(at: index)
            }
        } else if let column = object as? Column {
            try self.connection.execute(SQLite.Table.Column.Action.drop(column).SQL)
            if let index = column.table?.columns.index(where: { $0.name == column.name }) {
                column.table?.columns.remove(at: index)
            }
        }
    }
    
    open override func exists<T: DBObject>(_ object: T) -> Bool {
        if let table = object as? Table {
            if let _ = self.tables.find(predicate: { $0.name == table.name }) {
                return true
            }
            do {
                let result = try self.connection.execute_query("SELECT name FROM sqlite_master WHERE type='table' AND name='\(table.name)';")
                return !result.hashes.isEmpty
            } catch {}
            return false
        } else if let column = object as? Column {
            return column.table?.columns.find(predicate: { $0.name == column.name }) != nil
        }
        return false
    }
    
    open override func reference(_ to: String, on: String, options: [String: Any]? = nil) throws {
        let columnName = options?["column"] as? String ?? "\(on.singularized)_id"
        let table = Adapter.current.tables.find(predicate: { $0.name == to })!
        let column = Table.Column(name: columnName, type: .Int, table: table)
        try self.create(column)
    }
    
}
