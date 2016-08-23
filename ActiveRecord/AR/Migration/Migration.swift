//
//  Migration.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import ApplicationSupport

public protocol Migration {
    var timestamp: Int { get }
    func up()
    func down()
}

extension Migration {
    var id: String { return "\(self.dynamicType)" }
    var timestamp: Int { return 0 }
    
    var adapter: Adapter { return Adapter.current }
    
    func up() {}
    func down() {}
}

public let foreignKey = "foreignKey"
public let column = "column"

extension Migration {
    public func create<T: DBObject>(object: T, block: ((T) -> (Void))? = nil) {
        block?(object)
        MigrationsController.sharedInstance.check({ try self.adapter.create(object) })
    }
    
    public func rename<T: DBObject>(object: T, name: String) {
        MigrationsController.sharedInstance.check({ try self.adapter.rename(object, name: name) })
    }
    
    public func drop<T: DBObject>(object: T) {
        MigrationsController.sharedInstance.check({ try self.adapter.drop(object) })
    }
    
    public func exists<T: DBObject>(object: T) -> Bool {
        return (try? self.adapter.exists(object)) ?? false
    }
    
    public func reference(to: String, on: String, options: [String: Any]? = nil) {
        MigrationsController.sharedInstance.check({ try self.adapter.reference(to, on: on, options: options) })
    }
}