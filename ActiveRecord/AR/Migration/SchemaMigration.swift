//
//  SchemaMigration.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/1/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

class SchemasMigration: Migration {
    
    func up() {
        if self.exists(Table(MigrationsController.SchemaMigration.tableName)) == false {
            self.create(Table(MigrationsController.SchemaMigration.tableName)) { (table) -> (Void) in
                table.columns << Table.Column(name: "id", type: .String) { (column) in column.PK = true }
            }
        }
    }
    
    func down() {
        self.drop(Table(MigrationsController.SchemaMigration.tableName))
    }
    
}
