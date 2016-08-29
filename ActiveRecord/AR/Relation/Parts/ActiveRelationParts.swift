//
//  ActiveRelationParts.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/26/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

public protocol ActiveRelationPart: CustomStringConvertible {
    var priority: Int { get }
}

public struct WhereMerger: CustomStringConvertible {
    public var parts: [ActiveRelationPart] = []
    public var separator: String
    public var description: String {
        if !self.parts.isEmpty {
            return "WHERE " + self.parts.map({ $0.description }).joinWithSeparator(self.separator)
        }
        return ""
    }
    
    init(separator: String) {
        self.separator = separator
    }
}

public struct Where: ActiveRelationPart {
    public var priority: Int { return 1 }
    public var field: String
    public var values: Array<DatabaseRepresentable>
    public var negative = false
}

extension Where {
    public var description: String {
        if values.count == 1 {
            let expression = self.negative ? "!=" : "="
            if let record = values[0] as? ActiveRecord {
                // TODO: Use PK
                if let value = record.attributes["id"] as? DatabaseRepresentable {
                    return "\(field) \(expression) \(value.dbValue)"
                }
            } else {
                return "\(field) \(expression) \(values[0].dbValue)"
            }
        } else {
            var statement = ""
            if let records = values as? [ActiveRecord] {
                statement = records.map({ ($0.attributes["id"] as! DatabaseRepresentable).dbValue }).flatMap({$0}).map({ "\($0)" }).joinWithSeparator(", ")
            } else {
                statement = values.map({ "\($0.dbValue)" }).joinWithSeparator(", ")
            }
            let expresssion = self.negative ? "NOT IN" : "IN"
            return "\(field) \(expresssion) (\(statement))"
        }
        return ""
    }
}

public struct Includes: ActiveRelationPart {
    public var priority: Int { return -1 }
    public var records: [ActiveRecord.Type] = []
    public var description: String {
        return "Includes of \(self.records)"
    }
}

public struct Offset: ActiveRelationPart {
    public var priority: Int { return 2 }
    public var count: Int
}

extension Offset {
    public var description: String {
        return "OFFSET \(count)"
    }
}

public struct Limit: ActiveRelationPart {
    public var priority: Int { return 3 }
    public var count: Int
}

extension Limit {
    public var description: String {
        return "LIMIT \(count)"
    }
}

public struct Order: ActiveRelationPart {
    public var priority: Int { return 1 }
    public enum Direction: String {
        case Ascending = "ASC"
        case Descending = "DESC"
        case Random
    }
    
    public var field: String
    public var direction: Direction
}

extension Order {
    public var description: String {
        return "\(field) \(direction)"
    }
}

public struct Pluck: ActiveRelationPart {
    public var priority: Int { return 0 }
    public var fields: Array<String>
}

extension Pluck {
    public var description: String {
        return self.fields.isEmpty ? "*" : self.fields.joinWithSeparator(",")
    }
}