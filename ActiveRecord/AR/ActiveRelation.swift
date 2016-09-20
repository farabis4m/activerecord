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
    
    func clause(_ tableName: String) -> String {
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

open class ActiveRelation<T:ActiveRecord> {
    
    fileprivate var klass: T.Type?
    fileprivate var model: T?
    fileprivate var connection: Connection { return Adapter.current.connection }
    
    fileprivate var attributes: [String: Any]?
    
    open var tableName: String {
        return T.tableName
    }
    
    fileprivate var action = SQLAction.Select
    
    fileprivate var chain: [ActiveRelationPart] = []
    
    fileprivate var include: [ActiveRecord.Type] = []
    fileprivate var whereMerger = WhereMerger(separator: " AND ")
    
    
    //MARK: - Lifecycle
    
    public init() {
    }
    
    public init(with klass: T.Type) {
        self.klass = klass
    }
    
    public init(model: T) {
        self.klass = type(of: model)
        self.model = model
    }
    
    //MARK: - Chaining
    
    open func includes(_ records: [ActiveRecord.Type]) -> Self {
        self.include << records
        return self
    }
    
    //    public func preload(record: ActiveRecord.Type) -> Self {
    //        self.preload << record
    //        return self
    //    }
    
    open func pluck(_ fields: Array<String>) -> Self {
        self.chain.append(Pluck(fields: fields))
        return self
    }
    
    open func `where`(_ statement: [String: Any]) -> Self {
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
    
    open func `whereNot`(_ statement: [String: Any]) -> Self {
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
    
    open func whereIs(_ statement: [String: Any]) -> Self {
        return self.`where`(statement)
    }
    
    open func order(_ attributes: [String : String]) -> Self {
        if let field = attributes.keys.first, let order = attributes[field], let direction = Order.Direction(rawValue: order) {
            chain.append(Order(field: field, direction: direction))
        }
        return self
    }
    
    open func limit(_ value: Int) -> Self {
        chain.append(Limit(count: value))
        return self
    }
    
    open func offset(_ value: Int) -> Self {
        chain.append(Offset(count: value))
        return self
    }
    
    //MARK: - ActiveRecordRelationProtocol
    
    open func updateAll(_ attrbiutes: [String : Any]) throws -> Bool {
        self.action = .Update
        let _ = try self.execute()
        return false
    }
    
    open func destroyAll() throws -> Bool {
        self.action = .Delete
        let _ = try self.execute()
        return false
    }
    
    //MARK: -
    
    open func execute(_ strict: Bool = false) throws -> Array<T> {
        self.chain.sorted { $0.priority < $1.priority }
        
        let pluck: Pluck!
        if let index = self.chain.index(where: { $0 is Pluck }) {
            pluck = self.chain[index] as! Pluck
            self.chain.remove(at: index)
        } else {
            pluck = Pluck(fields: [])
        }
        let chainClause = self.chain.map({ "\($0)" }).joined(separator: " ")
        let SQLStatement = String(format: self.action.clause(self.tableName), pluck.description) + " " +  self.whereMerger.description + " " + chainClause + ";"
        let result = try self.connection.execute_query(SQLStatement)
        let table = Adapter.current.structure(T.tableName)
        var items = Array<T>()
        var includes: [Result] = []
        var relations: [String: [String: [RawRecord]]] = [:]
        for include in self.include {
            let includeTable = Adapter.current.structure(include.tableName)
            if result.hashes.isEmpty { continue }
            let ids = result.hashes.map({ $0["id"] }).flatMap({ $0 }).flatMap({ $0 }).map({ String(describing: $0) }).joined(separator: ", ")
            var relatedSQL = ""
            if table.foreignColumns.contains(where: { $0.foreignColumn!.table!.name == include.tableName }) {
                let includeIds = result.hashes.map({ $0["\(include.resourceName)_\(includeTable.PKColumn.name)"] }).flatMap({ $0 }).flatMap({ $0 }).map({ String(describing: $0) }).joined(separator: ", ")
                relatedSQL = "SELECT * FROM \(include.tableName) WHERE \("\(includeTable.PKColumn.name)") IN (\(includeIds));"
            } else {
                relatedSQL = "SELECT * FROM \(include.tableName) WHERE \("\(T.modelName)_id") IN (\(ids));"
            }
            try self.connection.execute_query(relatedSQL)
            
            includes << result
            for hash in result.hashes {
                if let id = hash["\(T.modelName)_id"] as? DatabaseRepresentable {
                    let key = String(describing: id)
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
            if let id = hash["id"] as? DatabaseRepresentable, let relation = relations[String(describing: id)] {
                attrbiutes.merge(relation)
            }
            let item = T.init(attributes: attrbiutes)
            items.append(item)
        }
        if strict && items.isEmpty {
            throw ActiveRecordError.recordNotFound(attributes: self.attributes ?? [:])
        }
        return items
    }
    
}

// TODO: Add json serialization into String field for SQLite
//extension Array: DatabaseRepresetable {}
//extension Dictionary: DatabaseRepresetable {}
