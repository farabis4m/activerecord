//
//  ActiveRecord+Naming.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

extension ActiveRecord {
    /**
     The model table name.
     
     Nested classes are in scope. Let's say you have 
     Post.Comment class as output you receive `post_comments`
     */
    public static var tableName: String {
        // TODO: Simplify it.
        let projectPackageName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        let components = String(describing: self).characters.split(separator: ".").map({ String($0) }).filter({ $0 != projectPackageName })
        if let first = components.first {
            if let last = components.last , components.count > 1 {
                return "\(first.lowercased())_\(last.lowercased().pluralized)"
            }
            return first.lowercased().pluralized
        }
        return "active_records"
    }
    
    /**
     The model name.
     
     Nested classes are in scope.
     <ProjectModuleName>.User.Post -> User.Post
     */
    public final static var modelName: String {
        let projectPackageName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        return String(describing: self).components(separatedBy: ".").filter({ $0 != projectPackageName }).joined(separator: ",")
    }
}
