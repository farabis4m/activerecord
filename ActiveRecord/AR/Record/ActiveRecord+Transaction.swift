//
//  ActiveRecord+Transaction.swift
//  Pods
//
//  Created by Vlad Gorbenko on 8/25/16.
//
//

import Foundation

open class Transaction {
//    var parent: Transaction?
//    var nested: Transaction?
    
    
    open static func perform(_ block: () throws -> Void ) throws {
        do {
            try Adapter.current.connection.execute("BEGIN TRANSACTION;")
            // begin
            try block()
            // end
            try Adapter.current.connection.execute("END TRANSACTION;")
        } catch {
            // rollback
            throw error
        }
    }
}
