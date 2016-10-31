//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Corey Baines on 1/11/16.
//  Copyright © 2016 Corey Baines. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    
    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var pageNumber: NSNumber?
    @NSManaged var photos: NSSet?
    @NSManaged var pinTitle: String?
    
    
}
