//
//  Adapter.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation

enum DBError: ErrorType {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
    case Statement(message: String)
}

class Adapter {
    
    enum Type: String {
        case SQLite = "SQLite"
    }
    static var current: Adapter!
    static func adapter(settings: [String: Any]) -> Adapter {
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


    var connection: Connection!
    
    private var settings: [String: Any]?
    init(settings: [String: Any]) {
        self.settings = settings
        self.connection = self.connect(settings)
    }
    
    func indexes() -> Array<String> {
        return Array<String>()
    }
    
    //MARK: - Tables
    
    func tables() -> Array<String> {
        return Array<String>()
    }
    
    func structure(table: String) -> Dictionary<String, Table.Column> {
        return [:]
    }
    
    //MARK: - Utils
    
    func connect(settings: [String: Any]) -> Connection {
        do {
            return try Connection(settings["name"] as! String)
        } catch {
            print(error)
            fatalError("Closing application due to db connection error...")
        }
    }
    
    func disconnect() {
    }    
}