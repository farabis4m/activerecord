//
//  String+Helpers.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/2/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

import Foundation

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
        let regex = NSRegularExpression(pattern: "([a-z])_([A-Z])", options: NSRegularExpressionOptions.CaseInsensitive)
        value = regex.stringByReplacingMatchesInString(self, options: .ReportCompletion, range: NSRange(location: 0, length: self.characters.count), withTemplate: "$1$2.capitalizedString")
        return self
    }
    
    func sneakyString() -> String {
        let regex = NSRegularExpression(pattern: "([a-z])([A-Z])", options: NSRegularExpressionOptions.CaseInsensitive)
        value = regex.stringByReplacingMatchesInString(self, options: .ReportCompletion, range: NSRange(location: 0, length: self.characters.count), withTemplate: "$1_$2")
        return self
    }
    
}

