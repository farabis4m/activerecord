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
    public static func before(_ action: ActiveRecrodAction, callback: ActiveRecordCallback) throws {
        ActiveCallbackStorage.beforeStorage.set(self, action: action, callback: callback)
    }
    public static func after(_ action: ActiveRecrodAction, callback: ActiveRecordCallback) throws {
        ActiveCallbackStorage.afterStorage.set(self, action: action, callback: callback)
    }
}

// Instance callbacks
extension ActiveRecord {
    public func after(_ action: ActiveRecrodAction) throws { }
    public func before(_ action: ActiveRecrodAction) throws { }
}
