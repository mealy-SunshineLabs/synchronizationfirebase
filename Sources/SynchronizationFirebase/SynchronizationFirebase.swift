
import Synchronization
import Firebase
import FirebaseFirestoreSwift

public protocol FirebaseSynchronizable {
    static func firebasePath(for identifier: String, in coordinatorID: String) -> DocumentReference?
}

public class SynchronizationFirebase: SynchronizationRemote {
    
    public init() {}
    
    public let name = "Firebase"
    
    public func fetch<Item: Codable>(
        _ itemType: Item.Type,
        identifier: String,
        coordinatorID: String,
        modelVersion: Int,
        with remoteRuntimeCache: Any?,
        completion: @escaping (SynchronizationRemoteFetchResult<Item>) -> Void
    ) {
        guard
            let document = (itemType as? FirebaseSynchronizable.Type)?
                .firebasePath(for: identifier, in: coordinatorID)
        else {
            Logger.log?("\(itemType) should adopt FirebaseSynchronizable protocol in order to be synchronized.")
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
                guard document.exists else {
                    completion(
                        .init(
                            status: .nothingToFetch,
                            item: nil,
                            runtimeCache: .unchanged
                        )
                    )
                    return
                }
                do {
                    let item = try document.data(as: Synchronizable<Item>.self)
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
    
    public func push<Item: Codable>(
        item: Synchronizable<Item>,
        coordinatorID: String,
        with remoteRuntimeCache: Any?,
        completion: @escaping (SynchronizationRemotePushResult) -> Void
    ) {
        guard
            let document = (Item.self as? FirebaseSynchronizable.Type)?
                .firebasePath(for: item.identifier, in: coordinatorID)
        else {
            Logger.log?("\(Item.self) should adopt FirebaseSynchronizable protocol in order to be synchronized.")
            completion(
                .init(
                    status: .failure,
                    runtimeCache: .unchanged
                )
            )
            return
        }
        do {
            try document.setData(from: item) { error in
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
    
    public func subscribeCoordinator(with identifier: String) {}
    public func unsubscribeCoordinator(with identifier: String) {}
    
}

public extension Date {
    static var distantPastFirebaseSafe: Date {
        Date().addingTimeInterval(-50 * 365 * 24 * 60 * 60)
    }
}

