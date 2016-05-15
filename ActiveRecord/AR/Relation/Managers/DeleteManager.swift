//
//  DeleteManager.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/15/16.
//
//

class DeleteManager {
    
    let model: ActiveRecord
    
    init(model: ActiveRecord) {
        self.model = model
    }
    
    func execute() throws {
        let klass = self.model.dynamicType
        let structure = Adapter.current.structure(klass.tableName)
        if let PK = structure.values.filter({ return $0.PK }).first {
            if case let value?? = self.model.attributes[PK.name] {
                try Adapter.current.connection.execute("DELETE FORM \(klass.tableName) WHERE \(PK.name) = \(value.dbValue)")
            }
        }
    }
    
}
