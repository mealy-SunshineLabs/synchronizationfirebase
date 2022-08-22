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
    func local(from fetched: RemoteItem, with identifier: String, at coordinatorId: String) throws -> Synchronizable<LocalItem>
    func remote(from local: Synchronizable<LocalItem>, at coordinatorId: String) throws -> RemoteItem
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
                    status: .fetchingFailed(SynchronizationFirebaseError.invalidFirebaseDocumentPath),
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
                            status: .fetchingFailed(error ?? SynchronizationFirebaseError.unknownFirebaseFetchnigProblem),
                            item: nil,
                            runtimeCache: .unchanged
                        )
                    )
                    return
                }
                do {
                    guard
                        document.exists
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
                    let remoteItem = try document.data(as: RemoteItem.self)
                    let item = try local(from: remoteItem, with: identifier, at: coordinatorID)
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
                            status: .canNotParse(error),
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
                    status: .failure(SynchronizationFirebaseError.invalidFirebaseDocumentPath),
                    runtimeCache: .unchanged
                )
            )
            return
        }
        do {
            let remoteItem = try remote(from: localItem, at: coordinatorID)
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
                    status: .encodingFailure(error),
                    runtimeCache: .unchanged
                )
            )
        }
    }
    
}
