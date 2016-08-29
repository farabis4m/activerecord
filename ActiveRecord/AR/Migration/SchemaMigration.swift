//
//  SchemaMigration.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/1/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

class SchemasMigration: Migration {
    
    func up() throws {
        if self.exists(Table(MigrationsController.SchemaMigration.tableName)) == false {
            try self.create(Table(MigrationsController.SchemaMigration.tableName)) { (table) -> (Void) in
                table.columns << Table.Column(name: "id", type: .String) { (column) in column.PK = true }
            }
        }
    }
    
    func down() throws {
        try self.drop(Table(MigrationsController.SchemaMigration.tableName))
    }
    
}
