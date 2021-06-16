//
//  SynchronizationFirebaseRemote.swift
//
//
//  Created by Jan Mazurczak.
//

import Synchronization
import Firebase
import FirebaseFirestoreSwift

public protocol SynchronizationFirebaseRemote: SynchronizationRemote {
    associatedtype LocalItem: Codable
    associatedtype RemoteItem: Codable
    func local(from fetched: RemoteItem) throws -> Synchronizable<LocalItem>
    func remote(from local: Synchronizable<LocalItem>) throws -> RemoteItem
    func path(for identifier: String, in coordinatorID: String) -> DocumentReference?
}

public extension SynchronizationFirebaseRemote {
    
    func fetch(
        identifier: String,
        coordinatorID: String,
        modelVersion: Int,
        with remoteRuntimeCache: Any?,
        completion: @escaping (SynchronizationRemoteFetchResult<LocalItem>) -> Void
    ) {
        guard
            let document = path(for: identifier, in: coordinatorID)
        else {
            Logger.log?("Couldn't construct Firebase path for \(LocalItem.self) with id: \(identifier) in coordinator \(coordinatorID).")
            completion(
                .init(
                    status: .tooNewToParse,
                    item: nil,
                    runtimeCache: .unchanged
                )
            )
            return
        }
        document
            .getDocument(source: .server) { document, error in
                guard let document = document else {
                    if let error = error {
                        Logger.log?("Firebase item fetching error: \(error)")
                    } else {
                        Logger.log?("Firebase item unknown fetching error")
                    }
                    completion(
                        .init(
                            status: .fetchingFailed,
                            item: nil,
                            runtimeCache: .unchanged
                        )
                    )
                    return
                }
                do {
                    guard
                        document.exists,
                        let remoteItem = try document.data(as: RemoteItem.self)
                    else {
                        completion(
                            .init(
                                status: .nothingToFetch,
                                item: nil,
                                runtimeCache: .unchanged
                            )
                        )
                        return
                    }
                    let item = try local(from: remoteItem)
                    completion(
                        .init(
                            status: .fetched,
                            item: item,
                            runtimeCache: .unchanged
                        )
                    )
                } catch {
                    Logger.log?("Firebase item parsing error: \(error)")
                    completion(
                        .init(
                            status: .canNotParse,
                            item: nil,
                            runtimeCache: .unchanged
                        )
                    )
                }
            }
    }
    
    func push(
        localItem: Synchronizable<LocalItem>,
        coordinatorID: String,
        with remoteRuntimeCache: Any?,
        completion: @escaping (SynchronizationRemotePushResult) -> Void
    ) {
        guard
            let document = path(for: localItem.identifier, in: coordinatorID)
        else {
            Logger.log?("Couldn't construct Firebase path for \(LocalItem.self) with id: \(localItem.identifier) in coordinator \(coordinatorID).")
            completion(
                .init(
                    status: .failure,
                    runtimeCache: .unchanged
                )
            )
            return
        }
        do {
            let remoteItem = try remote(from: localItem)
            try document.setData(from: remoteItem) { error in
                if let error = error {
                    Logger.log?("Firebase pushing error: \(error)")
                }
                completion(
                    .init(
                        status: error == nil ? .success : .failureRefetchIsNeeded,
                        runtimeCache: .unchanged
                    )
                )
            }
        } catch {
            Logger.log?("Firebase encoding error: \(error)")
            completion(
                .init(
                    status: .encodingFailure,
                    runtimeCache: .unchanged
                )
            )
        }
    }
    
}
