//
//  ActiveRecord+Validation.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

extension ActiveRecord {
    public var errors: Errors {
        if self.isNewRecord {
            return self.validate(.Create)
        } else if self.isDirty {
            return self.validate(.Update)
        }
        return Errors(model: self)
    }
    public var isValid: Bool { return self.errors.isEmpty }
    
    public func validate(action: Action) -> Errors {
        var errors = Errors(model: self)
        let validators = self.validators(action)
        if !validators.isEmpty {
            for (attribute, value) in self.attributes {
                if let validator = validators[attribute] {
                    validator.validate(self, attribute: attribute, value: value, errors: &errors)
                }
            }
        }
        return errors
    }
    public func validators(action: Action) -> [String: Validator] {
        return [:]
    }
}