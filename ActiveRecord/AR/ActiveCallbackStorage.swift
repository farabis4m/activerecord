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
    
    func set(klass: Any, action: ActiveRecrodAction, callback: ActiveRecordCallback) {
        let key = "\(klass)"
        var actions = items[key] ?? [:]
        var callbacks = actions[action] ?? []
        callbacks << callback
        actions[action] = callbacks
        items[key] = actions
    }
    
    func get(klass: Any.Type, action: ActiveRecrodAction) -> Bucket {
        let key = "\(klass)"
        if let actions = items[key], callbacks = actions[action] {
            return Bucket(action: action, callbacks: callbacks)
        }
        return Bucket(action: action,callbacks: [])
    }
    
    struct Bucket {
        var action: ActiveRecrodAction
        var callbacks: [ActiveRecordCallback]
        
        func execute(record: ActiveRecord) {
            for callback in self.callbacks {
                callback(record, self.action)
            }
        }
    }
}