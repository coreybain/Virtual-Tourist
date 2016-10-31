//
//  Photos+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Corey Baines on 1/11/16.
//  Copyright © 2016 Corey Baines. All rights reserved.
//

import Foundation
import CoreData

extension Photos {
    
    @NSManaged var url: String?
    @NSManaged var id: String?
    @NSManaged var filePath: String?
    @NSManaged var title: String?
    @NSManaged var pin: Pin?
    
}
