//
//  InsertManager.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

class InsertManager {
    
    var model: ActiveRecord
    
    init(model: ActiveRecord) {
        self.model = model
    }
    
    func execute() throws {
        let klass = self.model.dynamicType
        let attributes = self.model.dirty
        let structure = Adapter.current.structure(klass.tableName)
        var columns = Array<String>()
        var values = Array<AnyType>()
        for key in structure.keys {
            let b = attributes[key.camelString()]
            if case let value?? = attributes[key.camelString()] {
                if let activeRecord = value as? ActiveRecord {
                    columns << "\(key)_id"
                    // TODO: How to check that related object has id
                    values << activeRecord.id!.dbValue
                } else {
                    columns << key
                    values << value.dbValue
                }
            }
        }
        do {
            if !columns.isEmpty && !values.isEmpty {
                if columns.count != values.count {
                    throw ActiveRecordError.ParametersMissing(record: self.model)
                }
                let result = try Adapter.current.connection.execute_query("INSERT INTO \(klass.tableName) (\(columns.joinWithSeparator(","))) VALUES (\(values.map({"\($0)"}).joinWithSeparator(",")));")
                if let id = Adapter.current.connection.lastInsertRowid {
                    self.model.id = Int(id)
                }
            }
            
        } catch {
            print("ERORR: \(error)")
        }
    }
    
}
