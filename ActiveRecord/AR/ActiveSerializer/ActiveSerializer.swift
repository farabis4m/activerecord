//
//  ActiveSerializer.swift
//  AR
//
//  Created by Vlad Gorbenko on 4/27/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

class ActiveSerializerCache {
    fileprivate static var cache = Dictionary<String, Mirror>()
    
    class func reflect(_ model:Any) -> Mirror {
        guard let mirror = self.cache["\(type(of: (model) as AnyObject))"] else {
            let mirror = Mirror(reflecting: model)
            self.cache["\(type(of: (model) as AnyObject))"] = mirror
            return mirror
        }
        return mirror
    }
}

class ActiveSerializer<T: ActiveRecord> {
    
    fileprivate var mirror: Mirror
    lazy var fields: [String:Any?] = {
        let mirror = Mirror(reflecting: T())
        var fields = [String: Any?]()
        for case let (label?, value) in mirror.children {
            fields[label] = value
        }
        return fields
    }()
    
    //MARK: - Lifecycle
    
    convenience init() {
        self.init(model: T())
    }
    
    init(model: T) {
        self.mirror = ActiveSerializerCache.reflect(model)
    }
    
    //MARK: - Serialization
    
    func serialize(_ attributes: [String: Any?]) -> T {
        return T()
    }
    
    func deserialize() -> [String: Any?] {
        return [:]
    }
    
}
