//
//  ActiveRecord+Attributes.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

extension ActiveRecord {
    public var attributes: [String: Any] {
        get {
            return getAttributes()
        }
        set {
            self.setAttrbiutes(newValue)
            ActiveSnapshotStorage.sharedInstance.set(self)
        }
    }
    public var defaultValues: [String: Any] {
        let attributes = self.attributes
        return attributes
        
    }
    public var dirty: [String: Any] {
        let snapshot = ActiveSnapshotStorage.sharedInstance.merge(self)
        var dirty = Dictionary<String, Any>()
        let attributes = self.attributes
        for (k, v) in attributes {
            let snapshotEmpty = snapshot[k] == nil
            let valueEmpty = (v as? DatabaseRepresetable) == nil
            print("\(k): \(snapshot[k]) v: \(v) se: \(snapshotEmpty) ve: \(valueEmpty)")
            if let value = snapshot[k] where (value == v) == false {
                dirty[k] = v
            } else {
                // TODO: Simplify it
                if let sn = snapshot[k], let ssn = sn {
                    if valueEmpty {
                        dirty[k] = ssn
                    }
                } else {
                    if !valueEmpty {
                        dirty[k] = v
                    }
                }
            }
        }
        return dirty
    }
    public func setAttrbiutes(attributes: [String: Any]) {}
    public func getAttributes() -> [String: Any] { return self.transformedAttributes() }
    public func transformedAttributes() -> [String: Any] {
        let reflections = _reflect(self)
        var fields = [String: Any]()
        let transformers = self.dynamicType.transformers()
        for index in 0.stride(to: reflections.count, by: 1) {
            let reflection = reflections[index]
            var result: Any
            var value = unwrap(reflection.1.value)
            if let url = value as? NSURL {
                result = NSURLTransformer.backward?(value)
            } else {
                if let transformer = transformers[reflection.0] {
                    result = transformer.backward?(value)
                } else {
                    result = value
                }
            }
            fields[reflection.0.sneakyString()] = result
        }
        return fields
    }
}

extension ActiveRecord {
    var fields: String {
        return "\(ActiveSerializer(model: self).fields)"
    }
}