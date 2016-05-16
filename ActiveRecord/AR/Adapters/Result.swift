//
//  Result.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/26/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation

public class Result {
    
    var columns: Array<String>
    var rows: Array<Array<Any?>>
    
    init() {
        self.columns = Array<String>()
        self.rows = Array<Array<Any?>>()
    }
    
    init(columns: Array<String>, rows: Array<Array<Any?>>) {
        self.columns = columns
        self.rows = rows
    }
    
    lazy var camelizedColumns: Array<String> = {
        var names = Array<String>()
        for column in self.columns {
            var name = String(column)
            while let range = name.rangeOfString("_") {
                let subRange = Range(range.startIndex.advancedBy(1)..<range.endIndex.advancedBy(1))
                let nextChar = column.substringWithRange(subRange)
                let replaceRange = Range(range.startIndex..<range.endIndex.advancedBy(1))
                name.replaceRange(replaceRange, with: nextChar.capitalizedString)
            }
            names.append(name)
        }
        return names
    }()
    
    lazy var hashes: Array<Dictionary<String, AnyType?>> = {
        var hashes = Array<Dictionary<String, AnyType?>>()
        for i in 0..<self.rows.count {
            var hash = Dictionary<String, AnyType?>()
            for j in 0..<self.columns.count {
                hash[self.columns[j]] = self.rows[i][j] as? AnyType
            }
            hashes.append(hash)
        }
        return hashes
    }()
}
