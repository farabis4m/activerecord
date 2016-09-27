//
//  Table.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

public protocol DBObject {}

public class Table: DBObject {
    public class Column: DBObject, CustomDebugStringConvertible {
        
        typealias DBType = Type
        typealias BaseInt = Int
        typealias BaseFloat = Float
        typealias BaseString = String
        typealias BaseBool = Bool
        typealias BaseDouble = Double
        public enum Type: String {
            case Bool = "bool"
            case String = "text"
            case Int = "int"
            case Decimal = "decimal"
            case Double = "double"
            case Date = "date"
            case Raw = "blob"
            
            var type: Any {
                switch self {
                case .Int: return BaseInt.self
                case .Decimal: return BaseFloat.self
                case .String: return BaseString.self
                case .Date: return NSDate.self
                case .Raw: return NSData.self
                case .Bool: return BaseBool.self
                case .Double: return BaseDouble.self
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
        
        public var `default`: Any?
        public var name: String
        public var type: Type?
        public var PK = false
        public var autoIncrement = true
        public var unique = false
        public var nullable = true
        public var length: Int?
        
        public var table: String?
        
        public init(name: String, type: Type, _ block: ((Column) -> (Void))? = nil) {
            self.name = name
            self.type = type
            block?(self)
        }
        public init(name: String, type: Type, table: String) {
            self.name = name
            self.type = type
            self.table = table
        }
        public init(name: String, table: String, _ block: ((Column) -> (Void))? = nil) {
            self.name = name
            self.table = table
            block?(self)
        }
        
        public var debugDescription: String {
            return "Column(name: \(self.name), type: \(self.type?.rawValue), primary: \(self.PK), nullable: \(self.nullable))"
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
    
    public var name: String
    public var columns = Array<Column>()
    
    public init(_ name: String) {
        self.name = name
    }
}

public class Function: DBObject {
    //TODO: Future
}

extension Table.Column: CustomStringConvertible {
    public var description: String {
        var string = "\(name) \(Adapter.current.persistedColumnTypes[type!]!)"
        if let length = self.length {
            string += "(\(length))"
        }
        if !self.nullable {
            string += " NOT NULL"
        }
        if self.PK {
            string += " PRIMARY KEY"
            if self.type == .Int && self.autoIncrement {
                string += " AUTOINCREMENT"
            }
        }
        return string
    }
}
