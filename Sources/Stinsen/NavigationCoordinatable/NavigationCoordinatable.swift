import Foundation
import SwiftUI

public protocol NavigationCoordinatable: Coordinatable {
    typealias Route = NavigationRoute
    typealias Root = NavigationRoute
    typealias Router = NavigationRouter<Self>
    associatedtype CustomizeViewType: View
    associatedtype RouterStoreType

    var routerStorable: RouterStoreType { get }
    
    var stack: CoordinatorStack<Self> { get }

    /**
     Implement this function if you wish to customize the view on all views and child coordinators, for instance, if you wish to change the `tintColor` or inject an `EnvironmentObject`.
     - Parameter view: The input view.
     - Returns: The modified view.
     */
    func customize(_ view: AnyView) -> CustomizeViewType
    
    /// Asks the coordinator that presents this coordinator to dismiss it.
    ///
    /// - Returns: `false` if no coordinator can dismiss this coordinator, for example the root coordinator of a tab.
    ///   Stinsen then does nothing and reports a misuse. Use `canDismissCoordinator` to check before.
    @discardableResult func dismissCoordinator(_ action: (() -> ())?) -> Bool
    
    /**
     Clears the stack.
     */
    @discardableResult func popToRoot(_ action: (() -> ())?) -> Self

    /**
     Appends a view to the navigation stack.

     - Parameter route: The route to append.
     - Parameter input: The parameters that are used to create the coordinator.
     */
    @discardableResult func route<Input, Output: View>(
        to route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) -> Self
    
    /**
     Appends a coordinator to the navigation stack.

     - Parameter route: The route to append.
     - Parameter input: The parameters that are used to create the coordinator.
     */
    @discardableResult func route<Input, Output: Coordinatable>(
        to route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) -> Output
    
    /**
     Appends a coordinator to the navigation stack.

     - Parameter route: The route to append.
     */
    @discardableResult func route<Output: Coordinatable>(
        to route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) -> Output
    
    /**
     Appends a view to the navigation stack.

     - Parameter route: The route to append.
     */
    @discardableResult func route<Output: View>(
        to route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) -> Self
    
    /**
     Searches the stack for the first route that matches the route. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) throws -> Output
    
    /**
     Searches the stack for the first route that matches the route. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) throws -> Self
    
    /**
     Searches the stack for the first route that matches the route. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     - Parameter input: The input that will be considered.
     - Parameter comparator: The function to use to determine if the inputs are equal
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) throws -> Output
    
    /**
     Searches the stack for the first route that matches the closure. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     - Parameter input: The input that will be considered.
     - Parameter comparator: The function to use to determine if the inputs are equal
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) throws -> Self
    
    /**
     Searches the stack for the first route that matches the route. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     - Parameter input: The input that will be considered. Since this function assumes input is Equatable, it will use the `==` function to determine equality.
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) throws -> Output
    
    /**
     Searches the stack for the first route that matches the closure. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     - Parameter input: The input that will be considered. Since this function assumes input is Equatable, it will use the `==` function to determine equality.
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) throws -> Self
    
    /**
     Searches the stack for the first route that matches the route. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>
    ) throws -> Output
    
    /**
     Searches the stack for the first route that matches the closure. If found, will remove
     everything after that route.

     - Parameter route: The route that will be focused.
     
     - Throws: `FocusError.routeNotFound`
               if the route was not found in the stack.
     */
    @discardableResult func focusFirst<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>
    ) throws -> Self
    
    @discardableResult func root<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Output
    
    @discardableResult func root<Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Self
    
    @discardableResult func root<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Output
    
    @discardableResult func root<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Self
    
    @discardableResult func root<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Output
    
    @discardableResult func root<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Self
    
    func isRoot<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Bool
    
    func isRoot<Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Bool

    func isRoot<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>
    ) -> Bool

    func isRoot<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>
    ) -> Bool

    func isRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Bool

    func isRoot<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Bool

    func isRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Bool

    func isRoot<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Bool
    
    @discardableResult func hasRoot<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>
    ) -> Output?
    
    @discardableResult func hasRoot<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Output?
    
    @discardableResult func hasRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Output?
    
    @discardableResult func hasRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Output?
}

public extension NavigationCoordinatable {
    var routerStorable: Self {
        get {
            self
        }
    }
    
    weak var parent: ChildDismissable? {
        get {
            return stack.parent
        } set {
            stack.parent = newValue
        }
    }

    func customize(_ view: AnyView) -> some View {
        return view
    }
    
    func canDismissChild<T: Coordinatable>(_ coordinator: T) -> Bool {
        stackIndex(of: coordinator) != nil
    }

    /// `true` if a coordinator presents this coordinator and can dismiss it.
    ///
    /// For example, the root coordinator of a tab or of the app cannot be dismissed.
    var canDismissCoordinator: Bool {
        stack.parent?.canDismissChild(self) ?? false
    }

    private func stackIndex<T: Coordinatable>(of coordinator: T) -> Int? {
        stack.value.firstIndex { item in
            guard let presentable = item.presentable as? StringIdentifiable else {
                return false
            }

            return presentable.id == coordinator.id
        }
    }

    @discardableResult func dismissChild<T: Coordinatable>(coordinator: T, action: (() -> Void)? = nil) -> Bool {
        guard let value = stackIndex(of: coordinator) else {
            reportMisuse("Cannot dismiss \(type(of: coordinator)), because it is not in the stack of \(type(of: self)).")
            return false
        }

        self.popTo(value - 1, action)
        return true
    }
    
    @discardableResult func dismissCoordinator(_ action: (() -> ())? = nil) -> Bool {
        guard let parent = stack.parent else {
            reportMisuse("Cannot dismiss \(type(of: self)), because no coordinator presents it. Check canDismissCoordinator first.")
            return false
        }

        // If the parent cannot dismiss this coordinator, the parent reports the misuse.
        return parent.dismissChild(coordinator: self, action: action)
    }
    
    /// Connects the stack to this coordinator and creates the root. Stinsen calls it before it uses the stack.
    internal func prepareStack() {
        if stack.coordinator !== self {
            stack.coordinator = self
        }

        if stack.rootItem == nil {
            setupRoot()
        }
    }

    internal func setupRoot() {
        let presentable: ViewPresentable
        if let route = self[keyPath: self.stack.initial] as? NavigationOutputable {
            presentable = route.using(coordinator: self, input: self.stack.initialInput as Any)
        } else {
            reportMisuse("The initial route of \(type(of: self)) is not a @Root or @Route. Stinsen shows an empty view.")
            presentable = AnyView(EmptyView())
        }

        self.stack.rootItem = NavigationRootItem(
            keyPath: self.stack.initial.hashValue,
            input: self.stack.initialInput,
            child: presentable
        )

        _ = CoordinatorPath.navigationStack(of: presentable)
    }

    func popLast(_ action: (() -> ())? = nil) {
        self.popTo(self.stack.value.count - 2, action)
    }

    internal func popTo(_ int: Int, _ action: (() -> ())? = nil) {
        stack.popTo(int, action)
    }

    func view() -> AnyView {
        prepareStack()
        return AnyView(ScreenView(coordinator: self, stack: stack, index: -1, item: nil, appliesCustomize: true))
    }

    @discardableResult func popToRoot(_ action: (() -> ())? = nil) -> Self {
        self.popTo(-1, action)
        return self
    }
    
    @discardableResult func route<Input, Output: Coordinatable>(
        to route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input,
        onDismiss: @escaping () -> ()
    ) -> Output {
        stack.dismissalAction[stack.value.count - 1] = onDismiss
        return self.route(to: route, input)
    }
    
    @discardableResult func route<Input, Output: Coordinatable>(
        to route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) -> Output {
        let transition = self[keyPath: route]
        let output = transition.closure(self)(input)
        stack.value.append(
            NavigationStackItem(
                presentationType: transition.type.type,
                presentable: output,
                keyPath: route.hashValue,
                input: input
            )
        )
        output.parent = self
        _ = CoordinatorPath.navigationStack(of: output)
        return output
    }
    
    @discardableResult func route<Output: Coordinatable>(
        to route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>,
        onDismiss: @escaping () -> ()
    ) -> Output {
        stack.dismissalAction[stack.value.count - 1] = onDismiss
        return self.route(to: route)
    }
    
    @discardableResult func route<Output: Coordinatable>(
        to route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) -> Output {
        let transition = self[keyPath: route]
        let output = transition.closure(self)(())
        stack.value.append(
            NavigationStackItem(
                presentationType: transition.type.type,
                presentable: output,
                keyPath: route.hashValue,
                input: nil
            )
        )
        output.parent = self
        _ = CoordinatorPath.navigationStack(of: output)
        return output
    }
    
    @discardableResult func route<Input, Output: View>(
        to route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input,
        onDismiss: @escaping () -> ()
    ) -> Self {
        stack.dismissalAction[stack.value.count - 1] = onDismiss
        return self.route(to: route, input)
    }
    
    @discardableResult func route<Input, Output: View>(
        to route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) -> Self {
        let transition = self[keyPath: route]
        let output = transition.closure(self)(input)
        self.stack.value.append(
            NavigationStackItem(
                presentationType: transition.type.type,
                presentable: output,
                keyPath: route.hashValue,
                input: input
            )
        )
        return self
    }
    
    @discardableResult func route<Output: View>(
        to route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>,
        onDismiss: @escaping () -> ()
    ) -> Self {
        stack.dismissalAction[stack.value.count - 1] = onDismiss
        return self.route(to: route)
    }
    
    @discardableResult func route<Output: View>(
        to route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) -> Self {
        let transition = self[keyPath: route]
        let output = transition.closure(self)(())
        self.stack.value.append(
            NavigationStackItem(
                presentationType: transition.type.type,
                presentable: output,
                keyPath: route.hashValue,
                input: nil
            )
        )
        return self
    }

    @discardableResult private func _focusFirst<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: (value: Input, comparator: ((Input, Input) -> Bool))?
    ) throws -> Output {
        guard let value = stack.value.enumerated().first(where: { item in
            guard item.element.keyPath == route.hashValue else {
                return false
            }
            
            guard let input = input else {
                return true
            }
            
            guard let compareTo = Self.storedInput(item.element.input, as: Input.self) else {
                return false
            }

            return input.comparator(compareTo, input.value)
        }) else {
            throw FocusError.routeNotFound
        }
        
        guard let output = value.element.presentable as? Output else {
            throw FocusError.routeNotFound
        }

        self.popTo(value.offset, nil)

        return output
    }
    
    @discardableResult private func _focusFirst<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: (value: Input, comparator: ((Input, Input) -> Bool))?
    ) throws -> Self {
        guard let value = stack.value.enumerated().first(where: { item in
            guard item.element.keyPath == route.hashValue else {
                return false
            }
            
            guard let input = input else {
                return true
            }
            
            guard let compareTo = Self.storedInput(item.element.input, as: Input.self) else {
                return false
            }

            return input.comparator(compareTo, input.value)
        }) else {
            throw FocusError.routeNotFound
        }
        
        self.popTo(value.offset, nil)
        
        return self
    }
    
    @discardableResult func focusFirst<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) throws -> Output {
        try self._focusFirst(route, nil)
    }
    
    @discardableResult func focusFirst<Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Void, Output>>
    ) throws -> Self {
        try self._focusFirst(route, nil)
    }
    
    @discardableResult func focusFirst<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) throws -> Output {
        try self._focusFirst(route, (value: input, comparator: comparator))
    }
    
    @discardableResult func focusFirst<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) throws -> Self {
        try self._focusFirst(route, (value: input, comparator: comparator))
    }
    
    @discardableResult func focusFirst<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) throws -> Output {
        try self._focusFirst(route, (value: input, comparator: { $0 == $1 }))
    }
    
    @discardableResult func focusFirst<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>,
        _ input: Input
    ) throws -> Self {
        try self._focusFirst(route, (value: input, comparator: { $0 == $1 }))
    }
    
    @discardableResult func focusFirst<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>
    ) throws -> Output {
        try self._focusFirst(route, nil)
    }
    
    @discardableResult func focusFirst<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, Presentation, Input, Output>>
    ) throws -> Self {
        try self._focusFirst(route, nil)
    }
    
    /// Returns the input that Stinsen stored for a route as `Input`. A `Void` route stores `nil`.
    private static func storedInput<Input>(_ input: Any?, as type: Input.Type) -> Input? {
        if let input = input as? Input {
            return input
        }

        return () as? Input
    }

    /// Replaces the root with `route`, unless `route` with the same input is the root already.
    @discardableResult private func _root<Output: Coordinatable, Input>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        input: Input,
        comparator: ((Input, Input) -> Bool)?
    ) -> Output {
        let inputItem = comparator.map { (input: input, comparator: $0) }
        if _isRoot(route, inputItem: inputItem), let current = stack.rootItem?.child as? Output {
            return current
        }

        let output = self[keyPath: route].closure(self)(input)

        stack.rootItem = NavigationRootItem(
            keyPath: route.hashValue,
            input: input,
            child: output
        )

        _ = CoordinatorPath.navigationStack(of: output)

        return output
    }

    /// Replaces the root with `route`, unless `route` with the same input is the root already.
    @discardableResult private func _root<Output: View, Input>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        input: Input,
        comparator: ((Input, Input) -> Bool)?
    ) -> Self {
        let inputItem = comparator.map { (input: input, comparator: $0) }
        if _isRoot(route, inputItem: inputItem) {
            return self
        }

        let output = self[keyPath: route].closure(self)(input)

        stack.rootItem = NavigationRootItem(
            keyPath: route.hashValue,
            input: input,
            child: AnyView(output)
        )

        return self
    }

    @discardableResult func root<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Output {
        self._root(route, input: (), comparator: nil)
    }

    @discardableResult func root<Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Self {
        self._root(route, input: (), comparator: nil)
    }

    @discardableResult func root<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Output {
        self._root(route, input: input, comparator: comparator)
    }

    @discardableResult func root<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Self {
        self._root(route, input: input, comparator: comparator)
    }

    @discardableResult func root<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Output {
        self._root(route, input: input, comparator: { $0 == $1 })
    }

    @discardableResult func root<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Self {
        self._root(route, input: input, comparator: { $0 == $1 })
    }

    private func _isRoot<Input, Output>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        inputItem: (input: Input, comparator: (Input, Input) -> Bool)?
    ) -> Bool {
        prepareStack()
        guard let rootItem = stack.rootItem, rootItem.keyPath == route.hashValue else {
            return false
        }

        guard let inputItem = inputItem else {
            return true
        }

        guard let compareTo = Self.storedInput(rootItem.input, as: Input.self) else {
            return false
        }

        return inputItem.comparator(compareTo, inputItem.input)
    }

    private func _hasRoot<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        inputItem: (input: Input, comparator: (Input, Input) -> Bool)?
    ) -> Output? {
        guard _isRoot(route, inputItem: inputItem) else {
            return nil
        }

        return stack.rootItem?.child as? Output
    }
    
    @discardableResult func isRoot<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Bool {
        return self._isRoot(route, inputItem: nil)
    }
    
    @discardableResult func isRoot<Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Bool {
        return self._isRoot(route, inputItem: nil)
    }

    @discardableResult func isRoot<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>
    ) -> Bool {
        return self._isRoot(route, inputItem: nil)
    }

    @discardableResult func isRoot<Input, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>
    ) -> Bool {
        return self._isRoot(route, inputItem: nil)
    }

    @discardableResult func isRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Bool {
        return self._isRoot(route, inputItem: (input: input, comparator: { $0 == $1 }))
    }

    func isRoot<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Bool {
        return self._isRoot(route, inputItem: (input: input, comparator: { $0 == $1 }))
    }

    func isRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Bool {
        return self._isRoot(route, inputItem: (input: input, comparator: comparator))
    }

    func isRoot<Input: Equatable, Output: View>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Bool {
        return self._isRoot(route, inputItem: (input: input, comparator: comparator))
    }
    
    @discardableResult func hasRoot<Input, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>
    ) -> Output? {
        return self._hasRoot(route, inputItem: nil)
    }
    
    @discardableResult func hasRoot<Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Void, Output>>
    ) -> Output? {
        return self._hasRoot(route, inputItem: nil)
    }
    
    @discardableResult func hasRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input
    ) -> Output? {
        return self._hasRoot(route, inputItem: (input: input, comparator: { $0 == $1 }))
    }
    
    @discardableResult func hasRoot<Input: Equatable, Output: Coordinatable>(
        _ route: KeyPath<Self, Transition<Self, RootSwitch, Input, Output>>,
        _ input: Input,
        comparator: @escaping (Input, Input) -> Bool
    ) -> Output? {
        return self._hasRoot(route, inputItem: (input: input, comparator: comparator))
    }
}
