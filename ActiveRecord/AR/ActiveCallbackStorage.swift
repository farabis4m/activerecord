//
//  ActiveCallbackStorage.swift
//  SQLite
//
//  Created by Vlad Gorbenko on 6/15/16.
//
//

import Foundation

typealias ActiveRecordCallback = ((ActiveRecord, ActiveRecrodAction) -> (Void))

class ActiveCallbackStorage {
    static let sharedInstance = ActiveCallbackStorage()
    
    private var items = Dictionary<String, Array<RawRecord>>()
    
    func set(klass: ActiveRecord.Type, callback: ActiveRecordCallback) {
        let key = "\(klass)"
        var callbacks: [ActiveRecordCallback] = items[key] ?? []
        callbacks << callback
        items[key] = callbacks
    }
    
    func get(klass: ActiveRecord) -> [ActiveRecordCallback] {
        let key = "\(klass)"
        return items[key] ?? []
    }
}