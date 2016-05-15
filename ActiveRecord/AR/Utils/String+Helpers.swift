//
//  String+Helpers.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/2/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

extension String {
    
    var quoted: String {
        var result = ""
        if self.hasPrefix("'") == false {
            result += "'"
        }
        result += self
        if self.hasSuffix("'") == false {
            result += "'"
        }
        return result
    }
    
}

extension String {
    
    func camelString() -> String {
        return self
    }
    
    func sneakyString() -> String {
        return self
    }
    
}

