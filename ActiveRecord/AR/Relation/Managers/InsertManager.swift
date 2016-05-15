//
//  InsertManager.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

class InsertManager {
    
    let model: ActiveRecord
    
    init(model: ActiveRecord) {
        self.model = model
    }
    
    func execute() throws {
        let klass = self.model.dynamicType
        print("\(klass)" + " " + klass.tableName)
        let attributes = self.model.dirty
        let structure = Adapter.current.structure(klass.tableName)
        var columns = Array<String>()
        var values = Array<AnyType>()
        print(structure.keys)
        for key in structure.keys {
            if let value = attributes[key.camelString()] as? AnyType {
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
        print(columns)
        print(values)
        do {
            if !columns.isEmpty && !values.isEmpty {
                if columns.count != values.count {
                    throw ActiveRecordError.ParametersMissing(record: self.model)
                }
                try Adapter.current.connection.execute("INSERT INTO \(klass.tableName) (\(columns.joinWithSeparator(","))) VALUES (\(values.map({"\($0)"}).joinWithSeparator(",")));")
            }
            
        } catch {
            print("ERORR: \(error)")
        }
    }
    
}
