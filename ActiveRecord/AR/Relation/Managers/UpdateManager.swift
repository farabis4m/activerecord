//
//  UpdateManager.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/17/16.
//
//

class UpdateManager: ActionManager {
    
    override func execute() throws {
        let klass = self.record.dynamicType
        let attributes = self.record.dirty
        print(self.record.attributes)
        print("DIRTY: \(attributes)")
        let structure = Adapter.current.structure(klass.tableName)
        
        var values = Dictionary<String, Any>()
        for key in attributes.keys {
            let value = attributes[key]
//            if let value = attributes[key] as? DatabaseRepresetable {
                if let activeRecord = value as? ActiveRecord {
                    // TODO: How to check that related object has id
                    let columnName = "\(key)_id"
                    if structure.keys.contains(columnName) {
                        values[columnName] = (activeRecord.id as! DatabaseRepresetable).dbValue
                    }
                } else {
                    if structure.keys.contains(key) {
                        if let v = value as? DatabaseRepresetable {
                            values[key] = v.dbValue
                        }
                    }
                }
//            }
        }
        do {
            if !values.isEmpty {
                if let PK = structure.values.filter({ return $0.PK }).first {
                    if let value = self.record.attributes[PK.name] as? DatabaseRepresetable {
                        try Adapter.current.connection.execute_query("UPDATE \(klass.tableName) SET \(values.map({ "\($0) = \($1)" }).joinWithSeparator(", ")) WHERE \(PK.name) = \(value.dbValue)")
                    }
                }
                
            }
        } catch {
            print("ERORR: \(error)")
        }
    }
    
}
