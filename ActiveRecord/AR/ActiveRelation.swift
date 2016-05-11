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

class ActiveRelation<T:ActiveRecord>: ActiveRecordRelationProtocol {

    private var klass: T.Type?
    private var model: T?
    private var connection: Connection {
        return Connection.current!
    }
    
    private var tableName: String {
        return T.tableName
    }
    
    private var action = SQLAction.Select
    
    private var chain = Array<ActiveRelationPart>()
    
    private var preload: [ActiveRecord.Type]?
    
    //MARK: - Lifecycle
    
    init() {
    }
    
    init(with klass: T.Type) {
        self.klass = klass
    }

    init(model: T) {
        self.klass = model.dynamicType
        self.model = model
    }
    
    //MARK: - Chaining
    
    func pluck(fields: Array<String>) -> Self {
        self.chain.append(Pluck(fields: fields))
        return self
    }
    
    func `where`(statement: Any) -> Self {
        if let attributes = statement as? Dictionary<String, Any> where attributes.isEmpty == false {
            for key in attributes.keys {
                if let values = attributes[key] as? Array<CustomStringConvertible> {
                    chain.append(Where(field: key, values: values))
                } else if let value = attributes[key] as? CustomStringConvertible {
                    chain.append(Where(field: key, values: [value]))
                }
            }
        }
        return self
    }
    
    func whereIs(statement: Any) -> Self {
        return self.`where`(statement)
    }
    
    func order(attributes: [String : String]) -> Self {
        if let field = attributes.keys.first, let order = attributes[field], let direction = Order.Direction(rawValue: order) {
            chain.append(Order(field: field, direction: direction))
        }
        return self
    }
    
    func limit(value: Int) -> Self {
        chain.append(Limit(count: value))
        return self
    }
    
    func offset(value: Int) -> Self {
        chain.append(Offset(count: value))
        return self
    }
    
    func preload(models: [ActiveRecord.Type]) -> Self {
        self.preload = models
        return self
    }
    
    //MARK: - ActiveRecordRelationProtocol
    
    func update(attributes: [String: Any?]? = nil) throws -> Bool {
        return true
    }

    func updateAll(attrbiutes: [String : Any?]) throws -> Bool {
        self.action = .Update
        let _ = try self.execute()
        return false
    }
    
    func destroyAll() throws -> Bool {
        self.action = .Delete
        let _ = try self.execute()
        return false
    }
    
    //MARK: -
    
    func execute() throws -> Array<T> {
        self.chain.sortInPlace { $0.priority < $1.priority }
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
            let item = T.init(attributes: hash)
            items.append(item)
            ActiveSnapshotStorage.sharedInstance.set(item)
        }
        return items
    }
    
}