//
//  ActionManager.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 5/17/16.
//
//

protocol Executable {
    public func execute() throws
}

protocol ActionManager: Executable {
    
    let record: ActiveRecord
    
    init(record: ActiveRecord)
}

extension ActionManager {
    init(record: ActiveRecord) {
        self.record = record
    }
}

extension ActionManager {
    public func execute() throws {}
}
