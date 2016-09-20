//
//  ActiveRecord.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport
import ObjectMapper

public enum ActiveRecordError: Error {
    case recordNotValid(record: ActiveRecord)
    case recordNotFound(attributes: [String: Any])
    case attributeMissing(record: ActiveRecord, name: String)
    case invalidAttributeType(record: ActiveRecord, name: String, expectedType: String)
    case parametersMissing(record: ActiveRecord)
}

func ==(lhs: ActiveRecord?, rhs: ActiveRecord?) -> Bool {
    if let r = rhs?.getAttributes()["id"] as? DatabaseRepresentable {
        return (lhs?.getAttributes()["id"] as? DatabaseRepresentable)?.equals(r) ?? false
    }
    return false
}

func ==(lhs: ActiveRecord, rhs: ActiveRecord) -> Bool {
    let leftPK = Adapter.current.structure(type(of: lhs).tableName).PKColumn
    let rightPK = Adapter.current.structure(type(of: rhs).tableName).PKColumn
    if let right = rhs.getAttributes()[rightPK.name] as? DatabaseRepresentable {
        let left = lhs.getAttributes()[leftPK.name] as? DatabaseRepresentable
        return left?.equals(right) ?? false
    }
    return false
}

public protocol ActiveRecord: Record, DatabaseRepresentable {
    static var tableName: String { get }
    static func acceptedNestedAttributes() -> [String]
    
    // Validators
    func validate(_ action: Action) -> Errors
    func validators(_ action: Action) -> [String: Validator]
    
    // Callbackcs
    func before(_ action: ActiveRecrodAction) throws
    func after(_ action: ActiveRecrodAction) throws
    
    static func before(_ action: ActiveRecrodAction, callback: ActiveRecordCallback) throws
    static func after(_ action: ActiveRecrodAction, callback: ActiveRecordCallback) throws
}

extension ActiveRecord {
    var rawType: String { return "ActiveRecord" }
}

extension ActiveRecord {
    // Returns sanitized id
    // DB will not allow to insert a record with nil PK
    var identifier: Any {
//        return self.id ?? Optional<Int>()
        // TODO: Compare PK values
//        Optional(
        return Optional<Int>()
    }
}

extension ActiveRecord {
    // TODO: Don't have any other opportunities to compare hashes
    var hashValue: DatabaseRepresentable? {
        // TODO: Compare PK values
        return 0
//        return self.id as? DatabaseRepresentable
    }
}

// Defaults
extension ActiveRecord {
    // Nested attributes
    public static func acceptedNestedAttributes() -> [String] { return [] }
}

extension ActiveRecord {
    public init(attributes: RawRecord) {
        self.init()
        let map = Map(mappingType: .fromJSON, JSONDictionary: attributes, toObject: true, context: nil)
        self.mapping(map)
        self.timeline.enqueue(attributes)
        try? self.after(.initialize)
    }
}

public enum ActiveRecrodAction: Int, Hashable {
    case initialize
    case create
    case update
    case destroy
    case save
    
    public var hashValue: Int {
        return self.rawValue
    }
}

public enum Action {
    case create
    case update
    case delete
}
