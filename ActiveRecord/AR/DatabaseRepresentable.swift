//
//  DatabaseRepresentable.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

// MARK: - Database represtable
// Because each database users different fields to represent data in db itself
// DatabaseRepresetable provides wrapping to give a garantee of safe data types

public protocol RawTypeRepresentable {
    // Returns string represetation of the type
    var rawType: String { get }
}

extension RawTypeRepresentable {
    var rawType: String {
        return "\(self)"
    }
}

public protocol DatabaseRepresetable: RawTypeRepresentable {
    // Returns type safe value
    var dbValue: Any { get }
}

extension DatabaseRepresetable {
    public var dbValue: Any { return self }
}

// TOOD: dbValue and dbType should return the type basing on the Adapter types

extension String: DatabaseRepresetable {
    public var rawType: String { return "String" }
    public var dbValue: Any { return "'\(self)'" }
}
extension Int: DatabaseRepresetable {
    public var rawType: String { return "Int" }
}
extension Float: DatabaseRepresetable {
    public var rawType: String { return "Float" }
}
extension Bool: DatabaseRepresetable {
    public var rawType: String { return "Bool" }
    public var dbValue: Any { return Int(self) }
}
extension Double: DatabaseRepresetable {
    public var rawType: String { return "Double" }
}

public typealias Date = NSDate
extension Date: DatabaseRepresetable {
    public var rawType: String { return "Date" }
    public var dbValue: Any { return "'\(self)'" }
}

extension ActiveRecord {
    var rawType: String { return "ActiveRecord" }
}