//
//  ActiveRelationParts.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/26/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

public protocol ActiveRelationPart {
    var priority: Int { get }
}

public struct Where: ActiveRelationPart {
    public var priority: Int { return 1 }
    public var field: String
    public var values: Array<AnyType>
}

extension Where: CustomStringConvertible {
    public var description: String {
        if values.count == 1 {
            if let record = values[0] as? ActiveRecord {
                if let value = record.id {
                    return "WHERE \(field) = \(value.dbValue)"
                }
            } else {
                return "WHERE \(field) = \(values[0].dbValue)"
            }
        } else {
            var statement = ""
            if let records = values as? [ActiveRecord] {
                statement = records.map({ $0.id?.dbValue }).flatMap({$0}).map({ "\($0)" }).joinWithSeparator(", ")
            } else {
                statement = values.map({ "\($0.dbValue)" }).joinWithSeparator(", ")
            }
            return "WHERE \(field) IN (\(statement))"
        }
        return ""
    }
}

public struct Preload: ActiveRelationPart {
    public var priority: Int { return -1 }
    public var records: [ActiveRecord.Type] = []
}

public struct Includes: ActiveRelationPart {
    public var priority: Int { return -1 }
    public var records: [ActiveRecord.Type] = []
}

public struct Offset: ActiveRelationPart {
    public var priority: Int { return 2 }
    public var count: Int
}

extension Offset: CustomStringConvertible {
    public var description: String {
        return "OFFSET \(count)"
    }
}

public struct Limit: ActiveRelationPart {
    public var priority: Int { return 3 }
    public var count: Int
}

extension Limit: CustomStringConvertible {
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

extension Order: CustomStringConvertible {
    public var description: String {
        return "\(field) \(direction)"
    }
}

public struct Pluck: ActiveRelationPart {
    public var priority: Int { return 0 }
    public var fields: Array<String>
}

extension Pluck: CustomStringConvertible {
    public var description: String {
        return self.fields.isEmpty ? "*" : self.fields.joinWithSeparator(",")
    }
}