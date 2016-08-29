
//
//  MigrationsController.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/1/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport
import ObjectMapper

public class MigrationsController {
    
    class SchemaMigration: ActiveRecord {
        var timeline: Timeline = Timeline()
        class var tableName: String {
            return "schema_migrations"
        }
        class func getTableName() -> String {
            return "schema_migrations"
        }
        var id: Any {
            get { return self.name }
            set { self.name = newValue as! String }
        }
        var name: String!
        required init() {}
        required init?(_ map: Map) {}
        
        func mapping(map: Map) {
            self.name <- map["id"]
        }
    }
    
    public static var sharedInstance = MigrationsController()
    
    public var migrations = Array<Migration>()
    var enabled = true
    
    //MARK: - Lifecycle
    
    public init() {}
    
    //MARK: - Setup
    
    public func setup() {
        try? SchemasMigration().up()
    }
    
    //MARK: - Migration management
    
    public func migrate() {
        self.migrations.sortInPlace({ $0.timestamp < $1.timestamp })
        let passed = try! SchemaMigration.all()
        let difference = Set(self.migrations.map({ $0.id })).subtract(Set(passed.map({ $0.name })))
        let pending = self.migrations.filter({ difference.contains($0.id) })
        self.enabled = false
        for migration in self.migrations.filter({ !pending.map{$0.id}.contains($0.id) }) {
            try? migration.up()
        }
        self.enabled = true
        for migration in pending {
            do {
                let shemaMigration = SchemaMigration(attributes: ["id" : migration.id ])
                try migration.up()
                try shemaMigration.save()
            } catch {
                print("Migrations")
            }
        }
        
    }
    
    public func up(migration: Migration) throws {
        try migration.up()
    }
    
    public func down(migration: Migration) throws {
        try migration.down()
    }
}

func ==(lhs: MigrationsController.SchemaMigration, rhs: MigrationsController.SchemaMigration) -> Bool {
    return lhs.name == rhs.name
}
