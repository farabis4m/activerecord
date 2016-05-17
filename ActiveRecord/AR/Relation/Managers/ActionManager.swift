//
//  ActionManager.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/17/16.
//
//

protocol Executable {
    func execute() throws
}

class ActionManager: Executable {
    
    var record: ActiveRecord
    
    init(record: ActiveRecord) {
        self.record = record
    }
    
    func execute() throws { }
}
