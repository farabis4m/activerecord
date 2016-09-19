//
//  Adapter.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation
import ApplicationSupport
import SwiftyBeaver

let SQLLog = SwiftyBeaver.self

public enum DBError: Error {
    case openDatabase(message: String)
    case prepare(message: String)
    case step(message: String)
    case bind(message: String)
    case statement(message: String)
}

open class Adapter {
    
    public enum Type: String {
        case SQLite = "SQLite"
    }
    open static var current: Adapter!
    open static func adapter(_ settings: [String: Any]) -> Adapter {
        let type = Type(rawValue: settings["adapter"] as! String)!
        switch type {
        case .SQLite: Adapter.current = SQLiteAdapter(settings: settings)
        }
        return Adapter.current
    }
    
    var columnTypes: [String : Table.Column.DBType] {
        return ["text" : .String,
                "int"  : .Int,
                "date" : .Date,
                "real" : .Decimal,
                "blob" : .Raw]
    }
    
    var persistedColumnTypes: [Table.Column.DBType : String] { return [:] }
    
    open var tables: [Table] = []
    
    open var connection: Connection!
    
    fileprivate var settings: [String: Any]?
    init(settings: [String: Any]) {
        self.settings = settings
        self.connection = self.connect()

        let console = ConsoleDestination()
        console.colored = true
        SQLLog.addDestination(console)
    }
    
    open func indexes() -> Array<String> {
        return Array<String>()
    }
    
    //MARK: - Tables
    
    open func structure(_ tableName: String) -> Table {
        return Table(tableName)
    }
    
    //MARK: - 
    
    open func create<T: DBObject>(_ object: T) throws {}
    open func rename<T: DBObject>(_ object: T, name: String) throws {}
    open func drop<T: DBObject>(_ object: T) throws {}
    open func exists<T: DBObject>(_ object: T) throws -> Bool { return false }
    open func reference(_ to: String, on: String, options: [String: Any]? = nil) throws {
//        if let foreignKey = options?["foreignKey"] as? Bool where foreignKey == true {
//            let SQL = "\(Table.Action.Alter.clause(to)) ADD CONSTRAINT \(to)_\(columnName) FOREIGN KEY (\(columnName)) REFERENCES \(on)(id);"
//            MigrationsController.sharedInstance.check({ try self.adapter.connection.execute(SQL) })
//        }
    }
    
    //MARK: - Utils
    
    open func connect() -> Connection {
        do {
            let dbName = self.settings?["name"] as! String
            return try Connection(dbName)
        } catch {
            print(error)
            fatalError("Closing application due to db connection error...")
        }
    }
    
    open func disconnect() {
        self.connection.close()
    }
    
    
    open func cast(_ value: Any, column: Table.Column) -> DatabaseRepresentable? {
        if let type = column.type {
            switch type {
            case .Bool: return value as? Bool as? DatabaseRepresentable
            case .Int: return value as? Int as? DatabaseRepresentable
            case .Date: return (value as? String as? DatabaseRepresentable) ?? (value as? NSDate as? DatabaseRepresentable)
            case .Decimal: return value as? Float as? DatabaseRepresentable
            case .String: return value as? String as? DatabaseRepresentable
            case .Raw: return value as? NSData as? DatabaseRepresentable
            case .Double: return value as? Double as? DatabaseRepresentable
            }
        }
        return nil
    }
}
