//
//  SynchronizationFirebaseError.swift
//  
//
//  Created by Jan Mazurczak on 13/10/2021.
//

import Foundation

public enum SynchronizationFirebaseError: Error {
    case invalidFirebaseDocumentPath
    case unknownFirebaseFetchnigProblem
    case appInternalProblemWithSynchronizationFirebaseRemoteAlignment
}
