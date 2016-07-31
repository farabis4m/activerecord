//
//  ActiveRecord+Attributes.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

extension ActiveRecord {
    

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