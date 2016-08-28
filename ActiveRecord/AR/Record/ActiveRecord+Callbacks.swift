//
//  ActiveRecord+Callbacks.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

// Global callbacks
extension ActiveRecord {
    public static func before(action: ActiveRecrodAction, callback: ActiveRecordCallback) throws {
        ActiveCallbackStorage.beforeStorage.set(self, action: action, callback: callback)
    }
    public static func after(action: ActiveRecrodAction, callback: ActiveRecordCallback) throws {
        ActiveCallbackStorage.afterStorage.set(self, action: action, callback: callback)
    }
}

// Instance callbacks
extension ActiveRecord {
    public func after(action: ActiveRecrodAction) throws { }
    public func before(action: ActiveRecrodAction) throws { }
}