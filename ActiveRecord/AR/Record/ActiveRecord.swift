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

public protocol ActiveRecord: Record, DatabaseRepresentable {
    static var tableName: String { get }
    static func acceptedNestedAttributes() -> [String]
    
    // Validators
    func validate(action: Action) -> Errors
    func validators(action: Action) -> [String: Validator]
    
    // Callbackcs
    func before(action: ActiveRecrodAction)
    func after(action: ActiveRecrodAction)
    
    static func before(action: ActiveRecrodAction, callback: ActiveRecordCallback)
    static func after(action: ActiveRecrodAction, callback: ActiveRecordCallback)
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
        var merged = self.defaultValues
        merged.merge(attributes)
        let map = Map(mappingType: .FromJSON, JSONDictionary: attributes, toObject: true, context: nil)
        self.mapping(map)
        self.after(.Initialize)
    }
}

public func ==(l: ActiveRecord?, r: ActiveRecord?) -> Bool {
    if let right = r {
        return l?.equals(right) ?? false
    }
    return false
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
