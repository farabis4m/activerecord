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
        let reflect = Mirror(reflecting: self)
        let projectPackageName = Bundle.main .object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        // TODO: Check what description returns instead of summary
        let components = reflect.description.characters.split(separator: ".").map({ String($0) }).filter({ $0 != projectPackageName })
        if let first = components.first {
            if let last = components.last , components.count > 1 {
                return "\(first.lowercased())_\(last.lowercased().pluralized)"
            }
            return first.lowercased().pluralized
        }
        return "active_records"
    }
    
    public final static var modelName: String {
        var className = "\(type(of: self))"
        if let typeRange = className.range(of: ".Type") {
            className.replaceSubrange(typeRange, with: "")
        }
        return className.lowercased()
    }
}
