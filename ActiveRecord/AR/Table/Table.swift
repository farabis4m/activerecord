//
//  Table.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

public protocol DBObject {}

public class Table: DBObject {
    class Column: DBObject, CustomDebugStringConvertible {
        
        typealias DBType = Type
        typealias BaseInt = Int
        typealias BaseFloat = Float
        typealias BaseString = String
        enum Type: String {
            case String = "text"
            case Int = "int"
            case Decimal = "decimal"
            case Date = "date"
            case Raw = "blob"
            
            var type: Any {
                switch self {
                case .Int: return BaseInt.self
                case .Decimal: return BaseFloat.self
                case .String: return BaseString.self
                case .Date: return NSDate.self
                case .Raw: return NSData.self
                }
            }
        }
        
        enum Action: String {
            case Add = "ADD"
            case Drop = "DROP"
            case Rename = "RENAME COLUMN"
            
            func clause(value: String) -> String {
                switch self {
                case .Add: return self.rawValue
                case .Drop: return self.rawValue
                case .Rename: return "\(self.rawValue) \(value) TO"
                }
            }
        }
        
        var `default`: Any?
        var name: String
        var type: Type?
        var PK = false
        var unique = false
        var nullable = true
        var length: Int?
        
        var table: String?
        
        init(name: String, type: Type, _ block: ((Column) -> (Void))? = nil) {
            self.name = name
            self.type = type
            block?(self)
        }
        init(name: String, type: Type, table: String) {
            self.name = name
            self.type = type
            self.table = table
        }
        init(name: String, table: String, _ block: ((Column) -> (Void))? = nil) {
            self.name = name
            self.table = table
            block?(self)
        }
        
        var debugDescription: String {
            return "Column(name: \(self.name), type: \(self.type!.rawValue), primary: \(self.PK), nullable: \(self.nullable))"
        }
    }
    enum Action: String {
        case Create = "CREATE TABLE"
        case Drop = "DROP TABLE"
        case Alter = "ALTER TABLE"
        
        func clause(tableName: String) -> String {
            return "\(self.rawValue) \(tableName)"
        }
    }
    
    var name: String
    var columns = Array<Column>()
    
    init(_ name: String) {
        self.name = name
    }
}

public class Function: DBObject {
    //TODO: Future
}

extension Table.Column: CustomStringConvertible {
    var description: String {
        var string = "\(name) \(type!)"
        if let length = self.length {
            string += "(\(length))"
        }
        if !nullable {
            string += " NOT NULL"
        }
        if PK {
            string += " PRIMARY KEY"
        }
        return string
    }
}
