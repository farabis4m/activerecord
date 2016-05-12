
//
//  MigrationsController.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/1/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

public class MigrationsController {
 
    class SchemaMigration: ActiveRecord, Equatable, Hashable {
        class var tableName: String {
            return "schema_migrations"
        }
        class func getTableName() -> String {
            return "schema_migrations"
        }
        var id: AnyType? {
            get { return self.name }
            set { self.name = newValue as! String}
        }
        var name: String!
        required init() {}
        
        func setAttrbiutes(attributes: [String: Any?]) {
            self.name = attributes["name"] as! String
        }
        
        //MARK: - Hashable
        
        var hashValue: Int {
            return self.name.hashValue
        }
    }
    
    public static var sharedInstance = MigrationsController()
    
    public var migrations = Array<Migration>()

    //MARK: - Lifecycle
    
    public init() {}
    
    //MARK: - Setup
    
    public func setup() {
        SchemasMigration().up()
    }
    
    //MARK: - Migration management
    
    public func migrate() {
        self.migrations.sortInPlace({ $0.timestamp > $1.timestamp })
        let difference = Set(self.migrations.map({ $0.id })).subtract(Set(try! SchemaMigration.all().map({ $0.name })))
        let pending = self.migrations.filter({ difference.contains($0.id) })
        var succeed = Array<Migration>()
        for migration in pending {
            if self.isFailed == false {
                migration.up()
                if self.isFailed == false {
                    succeed.append(migration)
                }
            }
        }
        let _ = succeed.map({ try? SchemaMigration.create(["name" :$0.id ]) })
    }
    
    public func up(migration: Migration) {
        migration.up()
    }
    
    public func down(migration: Migration) {
        migration.down()
    }
    
    //MARK: - Utils
    private var isFailed = false
    func check(block: ((Void) throws -> (Void))) {
        do {
            try block()
        } catch {
            print("\(error)")
            self.isFailed = true
        }
    }
    
}

func ==(lhs: MigrationsController.SchemaMigration, rhs: MigrationsController.SchemaMigration) -> Bool {
    return lhs.name == rhs.name
}
