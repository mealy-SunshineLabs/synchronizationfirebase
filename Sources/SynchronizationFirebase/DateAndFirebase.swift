//
//  DateAndFirebase.swift
//  
//
//  Created by Jan Mazurczak on 16/06/2021.
//

import Foundation

public extension Date {
    static var distantPastFirebaseSafe: Date {
        Date().addingTimeInterval(-50 * 365 * 24 * 60 * 60)
    }
}

