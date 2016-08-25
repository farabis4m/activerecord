//
//  ActiveRecord+Transaction.swift
//  Pods
//
//  Created by Vlad Gorbenko on 8/25/16.
//
//

import Foundation

public class Transaction {
//    var parent: Transaction?
//    var nested: Transaction?
    
    @warn_unused_result
    public static func perform(block: () throws -> Void ) throws {
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