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
    
    func get(klass: ActiveRecord, action: ActiveRecrodAction) -> [ActiveRecordCallback] {
        let key = "\(klass)"
        if let actions = items[key], callbacks = actions[action] {
            return callbacks
        }
        return []
    }
}