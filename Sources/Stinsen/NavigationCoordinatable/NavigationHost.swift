import Foundation
import SwiftUI

/// A coordinator stack that is above a path entry, and the screen in it that shows the entry.
struct PathAncestor {
    let stack: AnyCoordinatorStack
    let routerID: Int

    /// Keeps the coordinator alive while the screen animates away after a pop.
    let coordinator: AnyObject?
}

/// One pushed screen in the path of a `NavigationStack`.
///
/// Two entries are equal when they show the same item of the same stack.
nonisolated struct PathEntry: Hashable {
    let stackID: ObjectIdentifier
    let index: Int
    let itemID: UUID

    let stack: AnyCoordinatorStack
    let item: NavigationStackItem
    let ancestors: [PathAncestor]

    /// Keeps the coordinator alive while the screen animates away after a pop. The stack holds it weakly.
    let coordinator: AnyObject?

    static func == (lhs: PathEntry, rhs: PathEntry) -> Bool {
        lhs.stackID == rhs.stackID && lhs.index == rhs.index && lhs.itemID == rhs.itemID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stackID)
        hasher.combine(index)
        hasher.combine(itemID)
    }
}

/// Gives a coordinator stack access to the navigation stack of a child.
protocol WrappingCoordinator: AnyObject {
    /// The stack of the wrapped `NavigationCoordinatable` if its pushes go into the enclosing `NavigationStack`, else `nil`.
    var childNavigationStack: AnyCoordinatorStack? { get }
}

/// Derives the path of a `NavigationStack` from coordinator stacks.
enum CoordinatorPath {
    /// Returns the stack of `presentable` if it is a `NavigationCoordinatable` that shares the enclosing `NavigationStack`.
    static func navigationStack(of presentable: Any) -> AnyCoordinatorStack? {
        if let coordinator = presentable as? any NavigationCoordinatable {
            return preparedStack(of: coordinator)
        }

        if let wrapper = presentable as? WrappingCoordinator {
            return wrapper.childNavigationStack
        }

        return nil
    }

    private static func preparedStack<C: NavigationCoordinatable>(of coordinator: C) -> AnyCoordinatorStack {
        coordinator.prepareStack()
        return coordinator.stack
    }

    /// Returns the path of the `NavigationStack` whose root is the screen at `anchor` in `stack`.
    ///
    /// The path contains the push items after `anchor` and the push items of nested child coordinators.
    /// It stops at the first modal or full-screen item, because that item has its own `NavigationStack`.
    static func entries(stack: AnyCoordinatorStack, anchor: Int) -> [PathEntry] {
        var result: [PathEntry] = []
        append(stack: stack, from: anchor, ancestors: [], into: &result)
        return result
    }

    private static func append(
        stack: AnyCoordinatorStack,
        from anchor: Int,
        ancestors: [PathAncestor],
        into result: inout [PathEntry]
    ) {
        if anchor == -1, let root = stack.rootItem, let childStack = navigationStack(of: root.child) {
            append(
                stack: childStack,
                from: -1,
                ancestors: ancestors + [PathAncestor(stack: stack, routerID: -1, coordinator: stack.coordinatorObject)],
                into: &result
            )
        }

        var index = anchor + 1
        while let item = stack.value[safe: index], item.presentationType == .push {
            result.append(
                PathEntry(
                    stackID: ObjectIdentifier(stack),
                    index: index,
                    itemID: item.id,
                    stack: stack,
                    item: item,
                    ancestors: ancestors,
                    coordinator: stack.coordinatorObject
                )
            )

            if let childStack = navigationStack(of: item.presentable) {
                append(
                    stack: childStack,
                    from: -1,
                    ancestors: ancestors + [PathAncestor(stack: stack, routerID: index, coordinator: stack.coordinatorObject)],
                    into: &result
                )
            }

            index += 1
        }
    }

    /// Applies a path that `NavigationStack` changed, for example after a back swipe.
    ///
    /// For each stack that lost entries, pops to the item before its first removed entry.
    /// Stinsen does all pushes, so the function ignores added entries.
    static func apply(_ newPath: [PathEntry], to stack: AnyCoordinatorStack, anchor: Int) {
        let current = entries(stack: stack, anchor: anchor)

        guard newPath.count < current.count else {
            if newPath.count > current.count {
                reportMisuse("Stinsen owns the navigation path. Use the router to push routes, not NavigationLink(value:).")
            }
            return
        }

        var firstRemoved: [ObjectIdentifier: (stack: AnyCoordinatorStack, index: Int)] = [:]
        for entry in current[newPath.count...] {
            if let existing = firstRemoved[entry.stackID], existing.index <= entry.index {
                continue
            }
            firstRemoved[entry.stackID] = (entry.stack, entry.index)
        }

        for (stack, index) in firstRemoved.values {
            stack.popTo(index - 1)
        }
    }
}

/// A `NavigationStack` whose root is the screen at `anchor` in `stack`.
///
/// For a root anchor (`-1`), the view adds the `customize` modifications of the coordinator around the
/// `NavigationStack`. Thus the root and all pushed screens get them once, as children of one view.
/// A modal anchor does not add them, as in Stinsen 2.
struct NavigationHostView: View {
    let stack: AnyCoordinatorStack
    let anchor: Int
    let anchorItem: NavigationStackItem?
    var hidesNavigationBar = false

    var body: some View {
        if anchor == -1 {
            stack.customize(AnyView(navigationStack))
        } else {
            navigationStack
        }
    }

    private var navigationStack: some View {
        // Read the path here, so that Observation tracks every stack in the path.
        let entries = CoordinatorPath.entries(stack: stack, anchor: anchor)
        let stack = self.stack
        let anchor = self.anchor

        return SwiftUI.NavigationStack(
            path: Binding(
                get: { entries },
                set: { CoordinatorPath.apply($0, to: stack, anchor: anchor) }
            )
        ) {
            stack.screen(index: anchor, item: anchorItem, appliesCustomize: false)
                #if !os(macOS)
                .toolbar(hidesNavigationBar ? .hidden : .automatic, for: .navigationBar)
                #endif
                .navigationDestination(for: PathEntry.self) { entry in
                    DestinationView(entry: entry)
                }
        }
    }
}

/// The view of one pushed screen.
///
/// A destination gets its environment from the `NavigationStack`, not from the screen that pushed it.
/// The `NavigationHostView` gives the environment of the anchor coordinator. For each nested child
/// coordinator, this view adds the `customize` modifications and the router of the screen that shows the child.
struct DestinationView: View {
    let entry: PathEntry

    var body: some View {
        var view = entry.stack.screen(index: entry.index, item: entry.item, appliesCustomize: false)

        // The anchor coordinator is the first ancestor. The host already adds its `customize` modifications.
        if !entry.ancestors.isEmpty {
            view = entry.stack.customize(view)
        }

        for (offset, ancestor) in entry.ancestors.enumerated().reversed() {
            view = ancestor.stack.withRouter(view, routerID: ancestor.routerID)
            if offset > 0 {
                view = ancestor.stack.customize(view)
            }
        }

        return view.onDisappear {
            entry.stack.runPendingDismissals()
            for ancestor in entry.ancestors {
                ancestor.stack.runPendingDismissals()
            }
        }
    }
}
