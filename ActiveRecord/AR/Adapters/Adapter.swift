//
//  Adapter.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation

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
    
    public var connection: Connection!
    
    private var settings: [String: Any]?
    init(settings: [String: Any]) {
        self.settings = settings
        self.connection = self.connect()
    }
    
    public func indexes() -> Array<String> {
        return Array<String>()
    }
    
    //MARK: - Tables
    
    public func tables() -> Array<String> {
        return Array<String>()
    }
    
    public func structure(table: String) -> Dictionary<String, Table.Column> {
        return [:]
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
}