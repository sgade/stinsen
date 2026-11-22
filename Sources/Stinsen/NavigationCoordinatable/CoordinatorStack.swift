import Foundation
import Observation
import SwiftUI

struct NavigationRootItem {
    let id = UUID()
    let keyPath: Int
    let input: Any?
    let child: ViewPresentable
}

struct NavigationStackItem {
    let id = UUID()
    let presentationType: PresentationType
    let presentable: ViewPresentable
    let keyPath: Int
    let input: Any?
}

/// The type-erased base class of `CoordinatorStack`.
///
/// Stinsen uses this type to find the path of a `NavigationStack` across nested coordinators.
/// You do not use this type directly.
@Observable
public class AnyCoordinatorStack {
    /// The routes on top of the root, in order.
    var value: [NavigationStackItem] = []

    /// The root of the stack. Stinsen sets it when the coordinator shows for the first time.
    var rootItem: NavigationRootItem?

    /// Actions to do when the screen at the key becomes the top screen again.
    @ObservationIgnored var dismissalAction: [Int: () -> Void] = [:]

    /// Dismissal actions of popped push routes. They run when the popped screen disappears.
    @ObservationIgnored private var pendingDismissals: [() -> Void] = []

    /// The routers of the screens in this stack, keyed by the index of the screen.
    @ObservationIgnored var routers: [Int: AnyObject] = [:]

    @ObservationIgnored weak var parent: ChildDismissable?

    init() {}

    /// Removes all items after `index`. The index `-1` is the root.
    func popTo(_ index: Int, _ action: (() -> Void)? = nil) {
        guard index >= -1, index + 1 < value.count else {
            return
        }

        if let action {
            dismissalAction[index] = action
        }

        for removedIndex in (index + 1)..<value.count {
            let presenter = removedIndex - 1
            let isPush = value[removedIndex].presentationType == .push

            // A sheet that the remaining top screen shows runs its action in `onDismiss`.
            if !isPush && presenter == index {
                continue
            }

            if let action = dismissalAction.removeValue(forKey: presenter) {
                pendingDismissals.append(action)
            }
        }

        routers = routers.filter { $0.key <= index }
        value = Array(value.prefix(index + 1))
    }

    /// Runs the dismissal actions of popped push routes.
    func runPendingDismissals() {
        let actions = pendingDismissals
        pendingDismissals = []
        actions.forEach { $0() }
    }

    /// The coordinator of the stack. Path entries keep it alive while a popped screen animates away.
    var coordinatorObject: AnyObject? {
        nil
    }

    /// Makes the view of the screen at `index`. The index `-1` is the root.
    ///
    /// - Parameter item: The item that the screen shows. Use `nil` for the root.
    /// - Parameter appliesCustomize: If `true`, the view adds the `customize` modifications of the coordinator.
    func screen(index: Int, item: NavigationStackItem?, appliesCustomize: Bool) -> AnyView {
        fatalError("CoordinatorStack must override screen(index:item:appliesCustomize:)")
    }

    /// Adds the `customize` modifications of the coordinator to `view`.
    func customize(_ view: AnyView) -> AnyView {
        fatalError("CoordinatorStack must override customize(_:)")
    }

    /// Adds the router of the screen at `routerID` to the environment of `view`.
    func withRouter(_ view: AnyView, routerID: Int) -> AnyView {
        fatalError("CoordinatorStack must override withRouter(_:routerID:)")
    }
}

/// The stack of routes of a `NavigationCoordinatable`.
public final class CoordinatorStack<T: NavigationCoordinatable>: AnyCoordinatorStack {
    let initial: PartialKeyPath<T>
    let initialInput: Any?

    weak var coordinator: T?

    public init(initial: PartialKeyPath<T>, _ initialInput: Any? = nil) {
        self.initial = initial
        self.initialInput = initialInput
        super.init()
    }

    /// Returns the router of the screen at `id`. Stinsen keeps one router for each screen.
    func router(for id: Int) -> NavigationRouter<T.RouterStoreType>? {
        if let router = routers[id] as? NavigationRouter<T.RouterStoreType> {
            return router
        }

        guard let coordinator else {
            return nil
        }

        let router = NavigationRouter(id: id, coordinator: coordinator.routerStorable)
        RouterStore.shared.store(router: router)
        routers[id] = router
        return router
    }

    override var coordinatorObject: AnyObject? {
        coordinator
    }

    override func screen(index: Int, item: NavigationStackItem?, appliesCustomize: Bool) -> AnyView {
        guard let coordinator else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ScreenView(
                coordinator: coordinator,
                stack: self,
                index: index,
                item: item,
                appliesCustomize: appliesCustomize
            )
        )
    }

    override func customize(_ view: AnyView) -> AnyView {
        guard let coordinator else {
            return view
        }

        return AnyView(coordinator.customize(view))
    }

    override func withRouter(_ view: AnyView, routerID: Int) -> AnyView {
        guard let router = router(for: routerID) else {
            return view
        }

        return AnyView(view.environmentObject(router))
    }
}

/// Convenience checks against the navigation stack's contents
public extension AnyCoordinatorStack {
    /**
        The Hash of the route at the top of the stack
        - Returns: the hash of the route at the top of the stack or -1
     */
    var currentRoute: Int {
        return value.last?.keyPath ?? -1
    }

    /**
    Checks if a particular KeyPath is in a stack
     - Parameter keyPathHash:The hash of the keyPath
     - Returns: Boolean indiacting whether the route is in the stack
     */
    func isInStack(_ keyPathHash: Int) -> Bool {
        return value.contains { $0.keyPath == keyPathHash }
    }

    /**
    Checks if a parent coordinator
     - Returns: Boolean indiacting whether the coordinator has a parent
     */
    func hasParent() -> Bool {
        return self.parent != nil
    }
}
