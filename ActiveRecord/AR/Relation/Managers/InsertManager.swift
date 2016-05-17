//
//  InsertManager.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

class InsertManager: ActionManager {
    
    override func execute() throws {
        let klass = self.record.dynamicType
        print(self.record.attributes)
        print(self.record.dirty)
        let attributes = self.record.dirty
        let structure = Adapter.current.structure(klass.tableName)
        var columns = Array<String>()
        var values = Array<AnyType>()
        for key in attributes.keys {
            if case let value?? = attributes[key] {
                if let activeRecord = value as? ActiveRecord {
                    let columnName = "\(key)_id"
                    if structure.keys.contains(columnName) {
                        columns << columnName
                        // TODO: How to check that related object has id
                        values << activeRecord.id!.dbValue
                    }
                } else {
                    if structure.keys.contains(key) {
                        columns << key
                        values << value.dbValue
                    }
                }
            } else {
                // TODO: Update to nil value
            }
        }
        do {
            if !columns.isEmpty && !values.isEmpty {
                if columns.count != values.count {
                    throw ActiveRecordError.ParametersMissing(record: self.record)
                }
                let result = try Adapter.current.connection.execute_query("INSERT INTO \(klass.tableName) (\(columns.joinWithSeparator(", "))) VALUES (\(values.map({"\($0)"}).joinWithSeparator(", ")));")
                if let id = Adapter.current.connection.lastInsertRowid where self.record.id?.rawType == "Int"{
                    self.record.id = Int(id)
                }
            }
            
        } catch {
            print("ERORR: \(error)")
        }
    }
    
}
