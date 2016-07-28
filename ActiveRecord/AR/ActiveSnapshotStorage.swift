//
//  ActiveSnapshotStorage.swift
//  AR
//
//  Created by Vlad Gorbenko on 4/28/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

class ActiveSnapshotStorage {
    static let sharedInstance = ActiveSnapshotStorage()
    
    private var items = Dictionary<String, Array<RawRecord>>()
    
    init() { }
    
    func set(model: ActiveRecord) {
        if var modelStorage = self.items[self.hash(model)] {
            modelStorage.append(model.attributes)
        } else {
            self.clear(model)
        }
    }
    
    func get(model: ActiveRecord) -> RawRecord? {
        return self.items[self.hash(model)]?.last
    }
    
    func clear(model: ActiveRecord) {
        var modelStorage = Array<RawRecord>()
        modelStorage.append(model.attributes)
        self.items[self.hash(model)] = modelStorage
    }
    
    func merge(model: ActiveRecord) -> RawRecord {
        if let timeline = self.items[self.hash(model)] {
            var result: RawRecord = [:]
            for item in timeline {
                for key in item.keys {
                    result[key] = item[key]
                }
            }
            return result
        }
        return [:]
    }
    
    func hash(model: ActiveRecord) -> String {
        return "\(model.self)_\(model.id)"
    }
}
