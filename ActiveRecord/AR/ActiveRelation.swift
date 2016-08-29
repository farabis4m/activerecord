//
//  Relation.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

enum SQLAction: String {
    case Select = "SELECT"
    case Insert = "INSERT"
    case Update = "UPDATE"
    case Delete = "DELETE"
    
    func clause(tableName: String) -> String {
        switch self {
        // TODO: This is not pure swift solution
        case .Select: return "\(self.rawValue) %@ FROM \(tableName)"
        case .Insert: return "\(self.rawValue) INTO \(tableName)"
        case .Update: return "\(self.rawValue) \(tableName)"
        case .Delete: return "\(self.rawValue) FROM \(tableName)"
        }
    }
}

public typealias RawRecord = [String: Any]
public typealias RawRecords = [RawRecord]

public class ActiveRelation<T:ActiveRecord> {
    
    private var klass: T.Type?
    private var model: T?
    private var connection: Connection { return Adapter.current.connection }
    
    private var attributes: [String: Any]?
    
    public var tableName: String {
        return T.tableName
    }
    
    private var action = SQLAction.Select
    
    private var chain: [ActiveRelationPart] = []
    
    private var include: [ActiveRecord.Type] = []
    private var whereMerger = WhereMerger(separator: " AND ")
    
    
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
    
    public func includes(records: [ActiveRecord.Type]) -> Self {
        self.include << records
        return self
    }
    
    //    public func preload(record: ActiveRecord.Type) -> Self {
    //        self.preload << record
    //        return self
    //    }
    
    public func pluck(fields: Array<String>) -> Self {
        self.chain.append(Pluck(fields: fields))
        return self
    }
    
    public func `where`(statement: [String: Any]) -> Self {
        self.attributes = statement
        for key in statement.keys {
            if let values = statement[key] as? [DatabaseRepresentable] {
                whereMerger.parts << Where(field: key, values: values, negative: false)
            } else if let value = statement[key] as? DatabaseRepresentable {
                whereMerger.parts << Where(field: key, values: [value], negative: false)
            }
        }
        return self
    }
    
    public func `whereNot`(statement: [String: Any]) -> Self {
        self.attributes = statement
        for key in statement.keys {
            if let values = statement[key] as? [DatabaseRepresentable] {
                whereMerger.parts << Where(field: key, values: values, negative: true)
            } else if let value = statement[key] as? DatabaseRepresentable {
                whereMerger.parts << Where(field: key, values: [value], negative: true)
            }
        }
        return self
    }
    
    public func whereIs(statement: [String: Any]) -> Self {
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
    
    public func updateAll(attrbiutes: [String : Any]) throws -> Bool {
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
        
        let pluck: Pluck!
        if let index = self.chain.indexOf({ $0 is Pluck }) {
            pluck = self.chain[index] as! Pluck
            self.chain.removeAtIndex(index)
        } else {
            pluck = Pluck(fields: [])
        }
        let chainClause = self.chain.map({ "\($0)" }).joinWithSeparator(" ")
        let SQLStatement = String(format: self.action.clause(self.tableName), pluck.description) + " " +  self.whereMerger.description + " " + chainClause + ";"
        let result = try self.connection.execute_query(SQLStatement)
        let table = Adapter.current.structure(T.tableName)
        var items = Array<T>()
        var includes: [Result] = []
        var relations: [String: [String: [RawRecord]]] = [:]
        for include in self.include {
            let includeTable = Adapter.current.structure(include.tableName)
            if result.hashes.isEmpty { continue }
            let ids = result.hashes.map({ $0["id"] }).flatMap({ $0 }).flatMap({ $0 }).map({ String($0) }).joinWithSeparator(", ")
            var relatedSQL = ""
            if table.foreignColumns.contains({ $0.foreignColumn!.table!.name == include.tableName }) {
                let includeIds = result.hashes.map({ $0["\(include.resourceName)_\(includeTable.PKColumn.name)"] }).flatMap({ $0 }).flatMap({ $0 }).map({ String($0) }).joinWithSeparator(", ")
                relatedSQL = "SELECT * FROM \(include.tableName) WHERE \("\(includeTable.PKColumn.name)") IN (\(includeIds));"
            } else {
                relatedSQL = "SELECT * FROM \(include.tableName) WHERE \("\(T.modelName)_id") IN (\(ids));"
            }
            try self.connection.execute_query(relatedSQL)
            
            includes << result
            for hash in result.hashes {
                if let id = hash["\(T.modelName)_id"] as? DatabaseRepresentable {
                    let key = String(id)
                    var items: Array<RawRecord> = []
                    if var bindings = relations[key] {
                        if let rows = bindings["\(include.tableName)"] {
                            items = rows
                        } else {
                            items = Array<RawRecord>()
                            bindings["\(include.tableName)"] = items
                        }
                    } else {
                        items = Array<RawRecord>()
                        relations[key] = ["\(include.tableName)" : items]
                    }
                    items.append(hash)
                    relations[key] = ["\(include.tableName)" : items]
                }
            }
        }
        for hash in result.hashes {
            var attrbiutes = hash
            if let id = hash["id"] as? DatabaseRepresentable, let relation = relations[String(id)] {
                attrbiutes.merge(relation)
            }
            let item = T.init(attributes: attrbiutes)
            items.append(item)
        }
        if strict && items.isEmpty {
            throw ActiveRecordError.RecordNotFound(attributes: self.attributes ?? [:])
        }
        return items
    }
    
}

// TODO: Add json serialization into String field for SQLite
//extension Array: DatabaseRepresetable {}
//extension Dictionary: DatabaseRepresetable {}