//
//  Result.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/26/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation

open class Result {
    
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
            while let range = name?.range(of: "_") {
//                 let subRange = Range(range.startIndex.advancedBy(1)..<range.endIndex.advancedBy(1))
//                 let nextChar = column.substringWithRange(subRange)
//                 let replaceRange = Range(range.startIndex..<range.endIndex.advancedBy(1))
//                 name.replaceRange(replaceRange, with: nextChar.capitalizedString)
                
                
//                    range.index
                // let subRange = Range(<#T##String.CharacterView corresponding to your index##String.CharacterView#>.index(range.lowerBound, offsetBy: 1)..<<#T##String.CharacterView corresponding to your index##String.CharacterView#>.index(range.upperBound, offsetBy: 1))
                // let nextChar = column.substring(with: subRange)
                // let replaceRange = Range(range.lowerBound..<<#T##String.CharacterView corresponding to your index##String.CharacterView#>.index(range.upperBound, offsetBy: 1))
                // name.replaceSubrange(replaceRange, with: nextChar.capitalized)
            }
            names.append(name!)
        }
        return names
    }()
    
    lazy var hashes: Array<RawRecord> = {
        var hashes = Array<RawRecord>()
        for i in 0..<self.rows.count {
            var hash = RawRecord()
            for j in 0..<self.columns.count {
                hash[self.columns[j]] = self.rows[i][j]
            }
            hashes.append(hash)
        }
        return hashes
    }()
}
