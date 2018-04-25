//
//  MS_TableConfig+CoreDataProperties.swift
//  todoios
//
//  Created by Ilja Faerman on 22/06/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MS_TableConfig {

    @NSManaged var id: String?
    @NSManaged var key: String?
    @NSManaged var keyType: NSNumber?
    @NSManaged var table: String?
    @NSManaged var value: String?

}
