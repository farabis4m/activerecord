//
//  InsertManager.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport
import ObjectMapper

class InsertManager: ActionManager {
    
    override func execute() throws {
        let attributes = self.record.dirty
        let table = Adapter.current.structure(self.record.dynamicType.tableName)
        
//        var columns: [String] = []
//        var values: [DatabaseRepresentable] = []
//        for column in table.columns {
//            if let rawValue = attributes[column.name] {
//                if let type = column.type {
//                    if let foreignTable = column.foreignTable {
//                        let key = foreignTable.name.singularized
//                        let value = (attributes[key] as? [String: Any])?[foreignTable.PKColumn.name]
//                        
//                    } else {
//                        
//                    }
//                }
//                columns << column.name
////                values << value
//            }
//        }
        
        var columns = Array<String>()
        var values = Array<Any>()
        for key in attributes.keys {
            let value = attributes[key]
            if let activeRecord = value as? ActiveRecord {
                let columnName = "\(key)_id"
                if let _ = table.column(key) {
                    // TODO: How to check that related object has id
                    // TODO: Use confirg for id objects
                    if let id = activeRecord.attributes["id"] as? DatabaseRepresentable {
                        columns << columnName
                        values << id.dbValue
                    }
                }
            } else {
                if let _ = table.column(key), value = value as? DatabaseRepresentable {
                    columns << key
                    values << value.dbValue
                }
            }
//            } else {
//                // TODO: Update to nil value
//            }
        }
        if !columns.isEmpty && !values.isEmpty {
            if columns.count != values.count {
                SQLLog.error("ParametersMissing \(self.record).")
                throw ActiveRecordError.ParametersMissing(record: self.record)
            }
            let result = try Adapter.current.connection.execute_query("INSERT INTO \(table.name) (\(columns.joinWithSeparator(", "))) VALUES (\(values.map({"\($0)"}).joinWithSeparator(", ")));")
            if let id = Adapter.current.connection.lastInsertRowid where table.PKColumn.type == .Int {
                // TODO: To do user confirg
                let map = Map(mappingType: .FromJSON, JSONDictionary: ["id" : Int(id)], toObject: true, context: nil)
                self.record.mapping(map)
            }
        }
    }
}
