//
//  Helpers.swift
//  
//
//  Created by Jan Mazurczak on 16/06/2021.
//

import Synchronization

public protocol SynchronizationFirebaseRemoteMappingItemAsIs: SynchronizationFirebaseRemote where RemoteItem == Synchronizable<LocalItem> {}

public extension SynchronizationFirebaseRemoteMappingItemAsIs {
    func local(from fetched: RemoteItem, with identifier: String, at coordinatorId: String) throws -> Synchronizable<LocalItem> { fetched }
    func remote(from local: Synchronizable<LocalItem>, at coordinatorId: String) throws -> RemoteItem { local }
}

public extension SynchronizationFirebaseRemote {
    
    func fetch<Item: Codable>(
        _ itemType: Item.Type,
        identifier: String,
        coordinatorID: String,
        modelVersion: Int,
        with remoteRuntimeCache: Any?,
        completion: @escaping (SynchronizationRemoteFetchResult<Item>) -> Void
    ) {
        fetch(
            identifier: identifier,
            coordinatorID: coordinatorID,
            modelVersion: modelVersion,
            with: remoteRuntimeCache
        ) {
            guard let result = $0 as? SynchronizationRemoteFetchResult<Item> else {
                Logger.log?("🛑 There is a serious integration problem with \(Self.self) not aligning SynchronizationFirebaseRemote.")
                completion(
                    .init(
                        status: .canNotParse,
                        item: nil,
                        runtimeCache: .unchanged
                    )
                )
                return
            }
            completion(result)
        }
    }
    
    func push<Item: Codable>(
        item: Synchronizable<Item>,
        coordinatorID: String,
        with remoteRuntimeCache: Any?,
        completion: @escaping (SynchronizationRemotePushResult) -> Void
    ) {
        guard let localItem = item as? Synchronizable<LocalItem> else {
            Logger.log?("🛑 There is a serious integration problem with \(Self.self) not aligning SynchronizationFirebaseRemote.")
            completion(
                .init(
                    status: .encodingFailure,
                    runtimeCache: .unchanged
                )
            )
            return
        }
        push(
            localItem: localItem,
            coordinatorID: coordinatorID,
            with: remoteRuntimeCache,
            completion: completion
        )
    }
    
    func subscribeCoordinator(with identifier: String) {}
    func unsubscribeCoordinator(with identifier: String) {}

}
