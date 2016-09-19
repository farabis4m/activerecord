//
//  Connection.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation
import CSQLite
import SwiftyBeaver

open class Connection {
    fileprivate var _handle: OpaquePointer? = nil
    var handle: OpaquePointer { return _handle! }
    
    /// The location of a SQLite database.
    enum Location {
        
        /// An in-memory database (equivalent to `.URI(":memory:")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#sharedmemdb>
        case inMemory
        
        /// A temporary, file-backed database (equivalent to `.URI("")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#temp_db>
        case temporary
        
        /// A database located at the given URI filename (or path).
        ///
        /// See: <https://www.sqlite.org/uri.html>
        ///
        /// - Parameter filename: A URI filename
        case uri(String)
    }
    
    fileprivate let location: Location
    fileprivate let isReadOnly: Bool
    
    init(_ location: Location = .inMemory, readonly: Bool = false) throws {
        self.location = location
        self.isReadOnly = readonly
        try self.open()
    }
    
    convenience init(_ filename: String, readonly: Bool = false) throws {
        try self.init(.uri(filename), readonly: readonly)
    }
    
    deinit {
        self.close()
    }
    
    open func open() throws {
        let flags = self.isReadOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        try check(sqlite3_open_v2(location.description, &_handle, flags | SQLITE_OPEN_FULLMUTEX, nil))
        queue.setSpecific(key: /*Migrator FIXME: Use a variable of type DispatchSpecificKey*/ Connection.queueKey, value: queueContext)
        try self.execute("PRAGMA foreign_keys = ON;")
    }
    
    open func close() {
        sqlite3_close(handle)
    }
    
    var readonly: Bool { return sqlite3_db_readonly(handle, nil) == 1 }
    
    /// The last rowid inserted into the database via this connection.
    var lastInsertRowid: Int64? {
        let rowid = sqlite3_last_insert_rowid(handle)
        return rowid > 0 ? rowid : nil
    }
    
    /// The last number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    var changes: Int {
        return Int(sqlite3_changes(handle))
    }
    
    /// The total number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    var totalChanges: Int {
        return Int(sqlite3_total_changes(handle))
    }
    
    // MARK: - Execute
    
    /// Executes a batch of SQL statements.
    ///
    /// - Parameter SQL: A batch of zero or more semicolon-separated SQL
    ///   statements.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    open func execute(_ SQL: String) throws {
        SQLLog.info(SQL)
        try self.check(sqlite3_exec(self.handle, SQL, nil, nil, nil))
    }
    
    func execute_query(_ SQL: String) throws -> Result {
        SQLLog.info(SQL)
        let statement = try self.prepare(SQL)
        var columnTypes = Array<Int32>()
        var columns = Array<String>()
        let columnsCount = sqlite3_column_count(statement)
        var rows = Array<Array<Any?>>()
        while sqlite3_step(statement) == SQLITE_ROW {
            var row = Array<Any?>()
            for i in 0..<columnsCount {
                let columnType = sqlite3_column_type(statement, i)
                if columns.count < Int(columnsCount) {
                    columnTypes.append(columnType)
                    let columnName = String.fromCString(UnsafePointer(sqlite3_column_name(statement, i))) ?? ""
                    columns.append(columnName)
                }
                
                var value: Any? = nil
                let pointer = UnsafePointer<CChar>(sqlite3_column_text(statement, i))
                if let string = String.fromCString(pointer!) {
                    switch columnType {
                    case SQLITE_INTEGER: value = Int(string)
                    case SQLITE_FLOAT: value = Float(string)
                    case SQLITE_TEXT: value = string
                    default: value = nil
                    }
                }
                row.append(value)
            }
            rows.append(row)
        }
        return Result(columns: columns, rows: rows)
    }
    
    func prepare(_ SQL: String) throws -> OpaquePointer {
        var statement: OpaquePointer? = nil
        guard sqlite3_prepare(self.handle, SQL, -1, &statement, nil) == SQLITE_OK else {
            SQLLog.error("\(self.errorMessage) in \(SQL)")
            throw DBError.prepare(message: self.errorMessage)
        }
        return statement!
    }
    
    // MARK: - Error Handling
    
    func sync<T>(_ block: @escaping () throws -> T) rethrows -> T {
        var success: T?
        var failure: Error?
        
        let box: () -> Void = {
            do {
                success = try block()
            } catch {
                failure = error
            }
        }
        
        if DispatchQueue.getSpecific(Connection.queueKey) == queueContext {
            box()
        } else {
            queue.sync(execute: box) // FIXME: rdar://problem/21389236
        }
        
        if let failure = failure {
            try { () -> Void in throw failure }()
        }
        
        return success!
    }
    
    fileprivate var errorMessage: String {
        if let errorMessage = String.fromCString(sqlite3_errmsg(self.handle)) {
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    func check(_ resultCode: Int32, statement: String? = nil) throws -> Int32 {
        let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
        if !successCodes.contains(resultCode) {
            SQLLog.info(self.errorMessage)
            throw DBError.statement(message: self.errorMessage)
        }
        return resultCode
    }
    
    fileprivate var queue = DispatchQueue(label: "SQLite.Database", attributes: [])
    
    fileprivate static let queueKey = unsafeBitCast(Connection.self, to: UnsafeRawPointer.self)
    
    fileprivate lazy var queueContext: UnsafeMutableRawPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
    
    //    private enum Result : ErrorType {
    //
    //        private static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
    //
    //        case Error(message: String, code: Int32, statement: String?)
    //
    //        init?(errorCode: Int32, connection: Connection, statement: String? = nil) {
    //            guard !Result.successCodes.contains(errorCode) else { return nil }
    //
    //            let message = String.fromCString(sqlite3_errmsg(connection.handle))!
    //            self = Error(message: message, code: errorCode, statement: statement)
    //        }
    //
    //    }
}

extension Connection.Location : CustomStringConvertible {
    
    var description: String {
        switch self {
        case .inMemory:
            return ":memory:"
        case .temporary:
            return ""
        case .uri(let URI):
            return URI
        }
    }
    
}
