//
//  InsertManager.swift
//  AR
//
//  Created by Vlad Gorbenko on 5/3/16.
//  Copyright © 2016 Vlad Gorbenko. All rights reserved.
//

class InsertManager {
    
    let model: ActiveRecord
    
    init(model: ActiveRecord) {
        self.model = model
    }
    
    func execute() {
        let klass = self.model.dynamicType
        let attributes = self.model.getAttributes()
        let names = attributes
        let _ = try? Adapter.current.connection.execute("INSERT INTO \(klass.tableName)")
    }
    
}
