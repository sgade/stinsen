import Foundation

/// Gives the router of the most recent screen with a router of type `Value`.
///
/// The wrapper holds the router weakly. A router keeps its coordinator alive, and the coordinator
/// can keep the object that uses this wrapper alive (for example a view model), so a strong
/// reference would make a retain cycle. If the router does not exist anymore, the wrapper
/// gets the most recent router of the same type again.
@propertyWrapper public struct RouterObject<Value: Routable> {
    private var storage: RouterStore
    private var retrieved = WeakRef<AnyObject>()

    public var wrappedValue: Value? {
        mutating get {
            if let currentValue = retrieved.value as? Value {
                return currentValue
            }

            let value: Value? = storage.retrieve()
            retrieved = WeakRef(value: value)
            return value
        }
        @available(*, unavailable, message: "RouterObject cannot be set") set {}
    }

    public init() {
        self.storage = RouterStore.shared
    }
}

public class RouterStore {
    public static let shared = RouterStore()
    
    // an array of weak references
    private var routers = [WeakRef<AnyObject>]()
}

public extension RouterStore {
    func store<T: Routable>(router: T) {
        cleanupRouterStore()
        let ref = WeakRef<AnyObject>(value: router)
        self.routers.insert(ref, at: 0)
    }
    
    func retrieve<T: Routable>() -> T? {
        for router in self.routers {
            if let foundRouter = router.value as? T, router.value != nil {
                return foundRouter
            }
        }
        
        return nil
    }
    
    /// Removes all nil weak references
    private func cleanupRouterStore() {
        let notNilRouters = self.routers.filter({ $0.value != nil })
        self.routers = notNilRouters
    }
}
