//
//  Connection.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation
import CSQLite

public class Connection {
    private var _handle: COpaquePointer = nil
    var handle: COpaquePointer { return _handle }
    
    /// The location of a SQLite database.
    enum Location {
        
        /// An in-memory database (equivalent to `.URI(":memory:")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#sharedmemdb>
        case InMemory
        
        /// A temporary, file-backed database (equivalent to `.URI("")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#temp_db>
        case Temporary
        
        /// A database located at the given URI filename (or path).
        ///
        /// See: <https://www.sqlite.org/uri.html>
        ///
        /// - Parameter filename: A URI filename
        case URI(String)
    }
    
    private let location: Location
    private let isReadOnly: Bool
    
    init(_ location: Location = .InMemory, readonly: Bool = false) throws {
        self.location = location
        self.isReadOnly = readonly
        try self.open()
    }
    
    convenience init(_ filename: String, readonly: Bool = false) throws {
        try self.init(.URI(filename), readonly: readonly)
    }
    
    deinit {
        self.close()
    }
    
    public func open() throws {
        let flags = self.isReadOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        try check(sqlite3_open_v2(location.description, &_handle, flags | SQLITE_OPEN_FULLMUTEX, nil))
        dispatch_queue_set_specific(queue, Connection.queueKey, queueContext, nil)
    }
    
    public func close() {
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
    func execute(SQL: String) throws {
        print("SQL: \(SQL)")
        try self.check(sqlite3_exec(self.handle, SQL, nil, nil, nil))
    }
    
    func execute_query(SQL: String) throws -> Result {
        let statement = try self.prepare(SQL)
        print("SQL: \(SQL)")
        var columnTypes = Array<Int32>()
        var columns = Array<String>()
        let columnsCount = sqlite3_column_count(statement)
        //        for i in 0..<columnsCount {
        //            let columnType = sqlite3_column_type(statement, i)
        //            columnTypes.append(columnType)
        //            let columnName = String.fromCString(UnsafePointer(sqlite3_column_name(statement, i))) ?? ""
        //            columns.append(columnName)
        //        }
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
                if let string = String.fromCString(pointer) {
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
    
    func prepare(SQL: String) throws -> COpaquePointer {
        var statement: COpaquePointer = nil
        guard sqlite3_prepare(self.handle, SQL, -1, &statement, nil) == SQLITE_OK else {
            throw DBError.Prepare(message: self.errorMessage)
        }
        return statement
    }
    
    // MARK: - Error Handling
    
    func sync<T>(block: () throws -> T) rethrows -> T {
        var success: T?
        var failure: ErrorType?
        
        let box: () -> Void = {
            do {
                success = try block()
            } catch {
                failure = error
            }
        }
        
        if dispatch_get_specific(Connection.queueKey) == queueContext {
            box()
        } else {
            dispatch_sync(queue, box) // FIXME: rdar://problem/21389236
        }
        
        if let failure = failure {
            try { () -> Void in throw failure }()
        }
        
        return success!
    }
    
    private var errorMessage: String {
        if let errorMessage = String.fromCString(sqlite3_errmsg(self.handle)) {
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    func check(resultCode: Int32, statement: String? = nil) throws -> Int32 {
        let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
        if !successCodes.contains(resultCode) {
            throw DBError.Statement(message: self.errorMessage)
        }
        return resultCode
    }
    
    private var queue = dispatch_queue_create("SQLite.Database", DISPATCH_QUEUE_SERIAL)
    
    private static let queueKey = unsafeBitCast(Connection.self, UnsafePointer<Void>.self)
    
    private lazy var queueContext: UnsafeMutablePointer<Void> = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
    
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
        case .InMemory:
            return ":memory:"
        case .Temporary:
            return ""
        case .URI(let URI):
            return URI
        }
    }
    
}