//
//  DeleteManager.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/15/16.
//
//
import ApplicationSupport

class DeleteManager: ActionManager {
    
    override func execute() throws {
        let klass = self.record.dynamicType
        let table = Adapter.current.structure(klass.tableName)
        if let value = self.record.attributes[table.PKColumn.name] as? DatabaseRepresentable {
            try Adapter.current.connection.execute("DELETE FROM \(klass.tableName) WHERE \(table.PKColumn.name) = \(value.dbValue);")
        }
    }
}
