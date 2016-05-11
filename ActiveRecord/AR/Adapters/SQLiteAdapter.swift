//
//  SqliteAdapter.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/1/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

public class SQLiteAdapter: Adapter {

    override var columnTypes: [String : Table.Column.DBType] {
        return ["text" : .String,
                "int"  : .Int,
                "date" : .Date,
                "real" : .Decimal,
                "blob" : .Raw]
    }

    
//    let columnTypes = ["text" : Table.Column.Type.String,
//                       "int"  : .Int,
//                       "date" : .Date,
//                       "real" : .Decimal,
//                       "blob" : .Raw]
    
    override func tables() -> Array<String> {
        do {
            let result = try self.connection.execute_query("SELECT name FROM sqlite_master WHERE (type = 'table' OR type == 'view' AND NOT name = 'sqlite_sequence')")
            return result.hashes.map({ $0["name"] as! String })
        } catch {
            print("\(error)")
        }
        return super.tables()
    }
    
    override func structure(table: String) -> Dictionary<String, Table.Column> {
        do {
            let result = try self.connection.execute_query("PRAGMA table_info(\(table.quoted))")
            var structure = Dictionary<String, Table.Column>()
            for row in result.hashes {
                let columnName = row["name"] as! String
                let column = Table.Column(name: columnName, table: table) { column in
                    column.`default` = row["dfltValue"]
                    column.PK = row["pk"] as? Int == 1
                    column.nullable = row["notnull"] as? Int == 1
                    column.type = self.columnTypes[row["type"] as! String]
                }
                structure[columnName] = column
            }
            return structure
        } catch {
            print("\(error)")
        }
        return super.structure(table)
    }
    
}
