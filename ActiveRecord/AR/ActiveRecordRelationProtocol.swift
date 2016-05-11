//
//  ActiveRecordRelationProtocol.swift
//  ActiveRecord
//
//  Created by Vlad Gorbenko on 4/21/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

public protocol ActiveRecordRelationProtocol {
    
    func updateAll(attrbiutes: [String: Any?]) throws -> Bool
    func destroyAll() throws -> Bool
    
}