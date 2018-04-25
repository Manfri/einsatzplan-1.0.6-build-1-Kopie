//
//  Registration+CoreDataProperties.swift
//  todoios
//
//  Created by Ilja Faerman on 09/06/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Registration {

    @NSManaged var password: String?
    @NSManaged var checked: NSNumber?

}
