//
//  UpdateManager.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/17/16.
//
//

import ApplicationSupport

class UpdateManager: ActionManager {
    
    override func execute() throws {
        let klass = type(of: self.record)
        let attributes = self.record.dirty
        let table = Adapter.current.structure(klass.tableName)
        var values = Dictionary<String, Any>()
        for key in attributes.keys {
            let value = attributes[key]
            if let activeRecord = value as? ActiveRecord {
                // TODO: How to check that related object has id
                let columnName = "\(key)_id"
                if let _ = table.column(columnName) {
                    values[columnName] = (activeRecord.attributes["id"] as! DatabaseRepresentable).dbValue
                }
            } else {
                if let _ = table.column(key), let dbValue = value as? DatabaseRepresentable {
                    values[key] = dbValue.dbValue
                }
            }
        }
        if !values.isEmpty {
            if let value = self.record.attributes[table.PKColumn.name] as? DatabaseRepresentable {
                try Adapter.current.connection.execute_query("UPDATE \(klass.tableName) SET \(values.map({ "\($0) = \($1)" }).joined(separator: ", ")) WHERE \(table.PKColumn.name) = \(value.dbValue)")
            }
        }
    }
}
