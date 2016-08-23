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

public enum DBError: ErrorType {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
    case Statement(message: String)
}

public class Adapter {
    
    public enum Type: String {
        case SQLite = "SQLite"
    }
    public static var current: Adapter!
    public static func adapter(settings: [String: Any]) -> Adapter {
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
    
    public var tables: [Table] = []
    
    public var connection: Connection!
    
    private var settings: [String: Any]?
    init(settings: [String: Any]) {
        self.settings = settings
        self.connection = self.connect()

        let console = ConsoleDestination()
        console.colored = true
        SQLLog.addDestination(console)
    }
    
    public func indexes() -> Array<String> {
        return Array<String>()
    }
    
    //MARK: - Tables
    
    public func structure(tableName: String) -> Table {
        return Table(tableName)
    }
    
    //MARK: - 
    
    public func create<T: DBObject>(object: T) throws {}
    public func rename<T: DBObject>(object: T, name: String) throws {}
    public func drop<T: DBObject>(object: T) throws {}
    public func exists<T: DBObject>(object: T) throws -> Bool { return false }
    public func reference(to: String, on: String, options: [String: Any]? = nil) throws {
//        if let foreignKey = options?["foreignKey"] as? Bool where foreignKey == true {
//            let SQL = "\(Table.Action.Alter.clause(to)) ADD CONSTRAINT \(to)_\(columnName) FOREIGN KEY (\(columnName)) REFERENCES \(on)(id);"
//            MigrationsController.sharedInstance.check({ try self.adapter.connection.execute(SQL) })
//        }
    }
    
    //MARK: - Utils
    
    public func connect() -> Connection {
        do {
            let dbName = self.settings?["name"] as! String
            return try Connection(dbName)
        } catch {
            print(error)
            fatalError("Closing application due to db connection error...")
        }
    }
    
    public func disconnect() {
        self.connection.close()
    }
    
    
    public func cast(value: Any, column: Table.Column) -> DatabaseRepresentable? {
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