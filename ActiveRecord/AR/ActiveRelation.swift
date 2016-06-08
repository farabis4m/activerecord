//
//  Relation.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

enum SQLAction: String {
    case Select = "SELECT"
    case Insert = "INSERT"
    case Update = "UPDATE"
    case Delete = "DELETE"
    
    func clause(tableName: String) -> String {
        switch self {
        // TODO: This is not pure swift solution
        case .Select: return "\(self) %@ FROM \(tableName)"
        case .Insert: return "\(self) INTO \(tableName)"
        case .Update: return "\(self) \(tableName)"
        case .Delete: return "\(self) FROM \(tableName)"
        }
    }
}

public class ActiveRelation<T:ActiveRecord> {
    
    private var klass: T.Type?
    private var model: T?
    private var connection: Connection { return Adapter.current.connection }
    
    private var attributes: [String: AnyType]?
    
    private var tableName: String {
        return T.tableName
    }
    
    private var action = SQLAction.Select
    
    private var chain = Array<ActiveRelationPart>()
    
    private var preload: [ActiveRecord.Type] = []
    private var include: [ActiveRecord.Type] = []
    
    //MARK: - Lifecycle
    
    public init() {
    }
    
    public init(with klass: T.Type) {
        self.klass = klass
    }
    
    public init(model: T) {
        self.klass = model.dynamicType
        self.model = model
    }
    
    //MARK: - Chaining
    
    public func includes(record: ActiveRecord.Type) -> Self {
        self.include << record
        return self
    }
    
    public func includes(records: [ActiveRecord.Type]) -> Self {
        self.include << records
        return self
    }
    
    public func preload(record: ActiveRecord.Type) -> Self {
        self.preload << record
        return self
    }
    
    public func pluck(fields: Array<String>) -> Self {
        self.chain.append(Pluck(fields: fields))
        return self
    }
    
    public func `where`(statement: [String: AnyType]) -> Self {
        self.attributes = statement
        for key in statement.keys {
            if let values = statement[key] as? Array<AnyType> {
                chain.append(Where(field: key, values: values))
            } else if let value = statement[key] {
                chain.append(Where(field: key, values: [value]))
            }
        }
        return self
    }
    
    public func whereIs(statement: [String: AnyType]) -> Self {
        return self.`where`(statement)
    }
    
    public func order(attributes: [String : String]) -> Self {
        if let field = attributes.keys.first, let order = attributes[field], let direction = Order.Direction(rawValue: order) {
            chain.append(Order(field: field, direction: direction))
        }
        return self
    }
    
    public func limit(value: Int) -> Self {
        chain.append(Limit(count: value))
        return self
    }
    
    public func offset(value: Int) -> Self {
        chain.append(Offset(count: value))
        return self
    }
    
    //MARK: - ActiveRecordRelationProtocol
    
    public func updateAll(attrbiutes: [String : AnyType?]) throws -> Bool {
        self.action = .Update
        let _ = try self.execute()
        return false
    }
    
    public func destroyAll() throws -> Bool {
        self.action = .Delete
        let _ = try self.execute()
        return false
    }
    
    //MARK: -
    
    public func execute(strict: Bool = false) throws -> Array<T> {
        self.chain.sortInPlace { $0.priority < $1.priority }
        print(self.chain)
        let pluck: Pluck!
        if let index = self.chain.indexOf({ $0 is Pluck }) {
            pluck = self.chain[index] as! Pluck
            self.chain.removeAtIndex(index)
        } else {
            pluck = Pluck(fields: [])
        }
        let SQLStatement = String(format: self.action.clause(self.tableName), pluck.description) + " " + self.chain.map({ "\($0)" }).joinWithSeparator(" ") + ";"
        let result = try self.connection.execute_query(SQLStatement)
        var items = Array<T>()
        for hash in result.hashes {
            print(hash)
            let item = T.init(attributes: hash)
            items.append(item)
            ActiveSnapshotStorage.sharedInstance.set(item)
        }
        if strict && items.isEmpty {
            throw ActiveRecordError.RecordNotFound(attributes: self.attributes ?? [:])
        }
        return items
    }
    
}