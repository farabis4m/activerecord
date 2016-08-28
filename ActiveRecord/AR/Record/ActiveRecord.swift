//
//  ActiveRecord.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport
import ObjectMapper

public enum ActiveRecordError: ErrorType {
    case RecordNotValid(record: ActiveRecord)
    case RecordNotFound(attributes: [String: Any])
    case AttributeMissing(record: ActiveRecord, name: String)
    case InvalidAttributeType(record: ActiveRecord, name: String, expectedType: String)
    case ParametersMissing(record: ActiveRecord)
}

func ==(lhs: ActiveRecord?, rhs: ActiveRecord?) -> Bool {
    if let r = rhs?.getAttributes()["id"] as? DatabaseRepresentable {
        return (lhs?.getAttributes()["id"] as? DatabaseRepresentable)?.equals(r) ?? false
    }
    return false
}

func ==(lhs: ActiveRecord, rhs: ActiveRecord) -> Bool {
    let leftPK = Adapter.current.structure(lhs.dynamicType.tableName).PKColumn
    let rightPK = Adapter.current.structure(rhs.dynamicType.tableName).PKColumn
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
    func validate(action: Action) -> Errors
    func validators(action: Action) -> [String: Validator]
    
    // Callbackcs
    func before(action: ActiveRecrodAction) throws
    func after(action: ActiveRecrodAction) throws
    
    static func before(action: ActiveRecrodAction, callback: ActiveRecordCallback) throws
    static func after(action: ActiveRecrodAction, callback: ActiveRecordCallback) throws
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
        let map = Map(mappingType: .FromJSON, JSONDictionary: attributes, toObject: true, context: nil)
        self.mapping(map)
        self.timeline.enqueue(attributes)
        try? self.after(.Initialize)
    }
}

public enum ActiveRecrodAction: Int, Hashable {
    case Initialize
    case Create
    case Update
    case Destroy
    case Save
    
    public var hashValue: Int {
        return self.rawValue
    }
}

public enum Action {
    case Create
    case Update
    case Delete
}
