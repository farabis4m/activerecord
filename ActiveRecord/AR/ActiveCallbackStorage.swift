//
//  ActiveCallbackStorage.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 6/15/16.
//
//

import Foundation

public typealias ActiveRecordCallback = ((ActiveRecord, ActiveRecrodAction) -> (Void))

class ActiveCallbackStorage {
    static let afterStorage = ActiveCallbackStorage()
    static let beforeStorage = ActiveCallbackStorage()
    
    private var items: [String: [ActiveRecrodAction: [ActiveRecordCallback]]] = [:]
    
    func set(klass: ActiveRecord.Type, action: ActiveRecrodAction, callback: ActiveRecordCallback) {
        let key = "\(klass)"
        var actions = items[key] ?? [:]
        var callbacks = actions[action] ?? []
        callbacks << callback
        actions[action] = callbacks
        items[key] = actions
    }
    
    func get(klass: ActiveRecord, action: ActiveRecrodAction) -> Bucket {
        let key = "\(klass)"
        if let actions = items[key], callbacks = actions[action] {
            return Bucket(callbacks: callbacks)
        }
        return Bucket(callbacks: [])
    }
    
    struct Bucket {
        var callbacks: [ActiveRecordCallback]
        
        func execute(record: ActiveRecord, action: ActiveRecrodAction) {
            for callback in self.callbacks {
                callback(record, action)
            }
        }
    }
}