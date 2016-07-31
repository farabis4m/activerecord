//
//  InsertManager.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

class InsertManager: ActionManager {
    
    override func execute() throws {
        let klass = self.record.dynamicType
        print(self.record.attributes)
        print(self.record.dirty)
        let attributes = self.record.dirty
        let structure = Adapter.current.structure(klass.tableName)
        var columns = Array<String>()
        var values = Array<Any>()
        for key in attributes.keys {
            let value = attributes[key]
            // TODO: Change for optional checking
//            if  {
                if let activeRecord = value as? ActiveRecord {
                    let columnName = "\(key)_id"
                    if structure.keys.contains(columnName) {
                        // TODO: How to check that related object has id
                        // TODO: Use confirg for id objects
                        if let id = activeRecord.attributes["id"] as? DatabaseRepresentable {
                            columns << columnName
                            values << id.dbValue
                        }
                    }
                } else {
                    if structure.keys.contains(key) {
                        if let v = value as? DatabaseRepresentable {
                            columns << key
                            values << v.dbValue
                        }
                        
                    }
                }
//            } else {
//                // TODO: Update to nil value
//            }
        }
        do {
            if !columns.isEmpty && !values.isEmpty {
                if columns.count != values.count {
                    throw ActiveRecordError.ParametersMissing(record: self.record)
                }
                let result = try Adapter.current.connection.execute_query("INSERT INTO \(klass.tableName) (\(columns.joinWithSeparator(", "))) VALUES (\(values.map({"\($0)"}).joinWithSeparator(", ")));")
                let PK = structure.values.filter({ return $0.PK }).first
                if let id = Adapter.current.connection.lastInsertRowid where PK?.type == .Int {
                    // TODO: To do user confirg
                    self.record.setAttributes(["id" : Int(id)])
                }
            }
            
        } catch {
            print("ERORR: \(error)")
        }
    }
    
}
