//
//  ActiveRecord+Naming.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

extension ActiveRecord {
    public static var tableName: String {
        let reflect = _reflect(self)
        let projectPackageName = NSBundle.mainBundle() .objectForInfoDictionaryKey("CFBundleExecutable") as! String
        let components = reflect.summary.characters.split(".").map({ String($0) }).filter({ $0 != projectPackageName })
        if let first = components.first {
            if let last = components.last where components.count > 1 {
                return "\(first.lowercaseString)_\(last.lowercaseString.pluralized)"
            }
            return first.lowercaseString.pluralized
        }
        return "active_records"
    }
    
    public final static var modelName: String {
        var className = "\(self.dynamicType)"
        if let typeRange = className.rangeOfString(".Type") {
            className.replaceRange(typeRange, with: "")
        }
        return className.lowercaseString
    }
}