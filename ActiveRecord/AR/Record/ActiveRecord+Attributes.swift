//
//  ActiveRecord+Attributes.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation
import ObjectMapper

extension ActiveRecord {
    public func getAttributes() -> [String: Any] { return self.transformedAttributes() }
    public func transformedAttributes() -> [String: Any] { return self.toJSON() }
}

extension ActiveRecord {
    var fields: String {
        return "\(ActiveSerializer(model: self).fields)"
    }
}