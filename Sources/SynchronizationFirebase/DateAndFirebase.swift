//
//  DateAndFirebase.swift
//  
//
//  Created by Jan Mazurczak on 16/06/2021.
//

import Foundation

public extension Date {
    static var distantPastFirebaseSafe: Date {
        Date(timeIntervalSince1970: TimeInterval(0))
    }
}

