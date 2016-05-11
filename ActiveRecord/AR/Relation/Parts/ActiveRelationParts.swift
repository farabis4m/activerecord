//
//  ActiveRelationParts.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/26/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

protocol ActiveRelationPart {
    var priority: Int { get }
}

public struct Where: ActiveRelationPart {
    var priority: Int { return 1 }
    var field: String
    var values: Array<CustomStringConvertible>
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
    var priority: Int { return 2 }
    var count: Int
}

extension Offset: CustomStringConvertible {
    public var description: String {
        return "OFFSET \(count)"
    }
}

public struct Limit: ActiveRelationPart {
    var priority: Int { return 3 }
    var count: Int
}

extension Limit: CustomStringConvertible {
    public var description: String {
        return "LIMIT \(count)"
    }
}

public struct Order: ActiveRelationPart {
    var priority: Int { return 1 }
    public enum Direction: String {
        case Ascending = "ASC"
        case Descending = "DESC"
        case Random        
    }
    
    var field: String
    var direction: Direction
}

extension Order: CustomStringConvertible {
    public var description: String {
        return "\(field) \(direction)"
    }
}

public struct Pluck: ActiveRelationPart {
    var priority: Int { return 0 }
    public var fields: Array<String>
}

extension Pluck: CustomStringConvertible {
    public var description: String {
        return self.fields.isEmpty ? "*" : self.fields.joinWithSeparator(",")
    }
}