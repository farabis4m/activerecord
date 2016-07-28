//
//  Transformable.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/28/16.
//
//

import Foundation

public typealias ForwardBlock = ((Any) -> Any?)
public typealias BackwardBlock = ((Any) -> Any?)
public struct Transformer {
    public var forward: ForwardBlock?
    public var backward: BackwardBlock?
    
    public init(forward: ForwardBlock?, backward: BackwardBlock? = nil) {
        self.forward = forward
        self.backward = backward
    }
    public init(backward: BackwardBlock?) {
        self.backward = backward
    }
}

let NSURLTransformer = Transformer(forward: { (value) -> Any? in
    if let url = value as? String {
        return NSURL(string: url)
    }
    return value
    }, backward: { (value) -> Any? in
        if let url = value as? NSURL {
            return url.absoluteString
        }
        return value as? Any
})

public protocol Transformable {
    static func transformers() -> [String: Transformer]
}