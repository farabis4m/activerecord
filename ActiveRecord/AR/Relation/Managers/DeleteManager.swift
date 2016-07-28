//
//  DeleteManager.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/15/16.
//
//

class DeleteManager: ActionManager {
    
    override func execute() throws {
        let klass = self.record.dynamicType
        let structure = Adapter.current.structure(klass.tableName)
        if let PK = structure.values.filter({ return $0.PK }).first {
            if let value = self.record.attributes[PK.name] as? DatabaseRepresetable {
                try Adapter.current.connection.execute("DELETE FROM \(klass.tableName) WHERE \(PK.name) = \(value.dbValue)")
            }
        }
    }
}
