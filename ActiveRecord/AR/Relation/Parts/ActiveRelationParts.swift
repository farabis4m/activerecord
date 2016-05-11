//
//  ActiveRelationParts.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/26/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

public protocol ActiveRelationPart {
    public var priority: Int { get }
}

public struct Where: ActiveRelationPart {
    public var priority: Int { return 1 }
    public var field: String
    public var values: Array<CustomStringConvertible>
}

extension Where: CustomStringConvertible {
    public var description: String {
        if values.count == 1 {
            return "WHERE \(field) = \(values[0])"
        } else {
            let statememnt = values.map({ $0.description }).joinWithSeparator(",")
            return "WHERE \(field) IN (\(statememnt))"
        }
    }
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