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

public extension String {
    
    func camelString() -> String {
        return self.characters.split("_").map({ item in return String(item).capitalizedString }).joinWithSeparator("").lowercaseFirst
    }
    
    func sneakyString() -> String {
        let regex = try? NSRegularExpression(pattern: "([a-z])([A-Z])", options: NSRegularExpressionOptions.AllowCommentsAndWhitespace)
        let value = regex?.stringByReplacingMatchesInString(self, options: .ReportCompletion, range: NSRange(location: 0, length: self.characters.count), withTemplate: "$1_$2")
        if let result = value where result.isEmpty == false {
            return result.lowercaseString
        }
        return self
    }
    
    var first: String { return String(characters.prefix(1)) }
    var last: String { return String(characters.suffix(1)) }
    
    var uppercaseFirst: String { return first.uppercaseString + String(characters.dropFirst()) }
    var lowercaseFirst: String { return first.lowercaseString + String(characters.dropFirst()) }
    
}

