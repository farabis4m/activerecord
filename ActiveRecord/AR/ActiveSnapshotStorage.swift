//
//  ActiveSnapshotStorage.swift
//  AR
//
//  Created by Vlad Gorbenko on 4/28/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

class ActiveSnapshotStorage {
    static let sharedInstance = ActiveSnapshotStorage()
    
    private var items = Dictionary<String, Array<Dictionary<String, Any?>>>()
    
    init() { }
    
    func set(model: ActiveRecord) {
        if var modelStorage = self.items["\(model.self)_\(model.id)"] {
            modelStorage.append(model.attributes)
        } else {
            self.clear(model)
        }
    }
    
    func get(model: ActiveRecord) -> [String: Any?]? {
        return self.items["\(model.self)_\(model.id)"]?.last
    }
    
    func clear(model: ActiveRecord) {
        var modelStorage = Array<Dictionary<String, Any?>>()
        modelStorage.append(model.attributes)
        self.items["\(model.self)_\(model.id)"] = modelStorage
    }
}
