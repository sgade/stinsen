import SwiftUI
import Testing
@testable import Stinsen

final class TabsCoordinator: @MainActor TabCoordinatable {
    let child = TabChild(startingItems: [\TabsCoordinator.first, \TabsCoordinator.second])

    @Route(tabItem: makeTabItem) var first = makeFirst
    @Route(tabItem: makeTabItem) var second = makeSecond
    @Route(tabItem: makeTabItem) var notATab = makeFirst

    func makeFirst() -> NavigationStackCoordinator<ChildCoordinator> {
        NavigationStackCoordinator(ChildCoordinator())
    }

    func makeSecond() -> Text { Text("Second") }
    func makeTabItem(isActive: Bool) -> Text { Text("Tab") }
}

final class MissingInputCoordinator: @MainActor NavigationCoordinatable {
    let stack = CoordinatorStack(initial: \MissingInputCoordinator.numbered)

    @Root var numbered = makeNumbered

    func makeNumbered(_ number: Int) -> Text { Text("\(number)") }
}

/// Returns the misuses that Stinsen reports while `body` runs.
func misuses(during body: () throws -> Void) rethrows -> [StinsenMisuse] {
    var reported: [StinsenMisuse] = []
    let previous = StinsenMisuse.handler
    StinsenMisuse.handler = { reported.append($0) }
    defer { StinsenMisuse.handler = previous }

    try body()
    return reported
}

/// Stinsen must not stop the app for a navigation request that it cannot do.
/// It ignores the request, logs a fault, and calls `StinsenMisuse.handler`.
@Suite("Misuse does not crash")
struct MisuseTests {
    @Test("A coordinator without a presenter ignores dismissCoordinator")
    func dismissRootCoordinator() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)

        var dismissed = true
        let reported = misuses { dismissed = parent.dismissCoordinator() }

        #expect(!dismissed)
        #expect(reported.count == 1)
        #expect(parent.stack.value.count == 1)
    }

    @Test("The root coordinator of a tab ignores dismissCoordinator (the reported crash)")
    func dismissTabRoot() {
        let tabs = TabsCoordinator()
        _ = tabs.view()
        let wrapper = tabs.focusFirst(\.first)

        var results: [Bool] = []
        let reported = misuses {
            results.append(wrapper.child.dismissCoordinator())
            results.append(tabs.dismissChild(coordinator: wrapper, action: nil))
        }

        #expect(results == [false, false])
        #expect(reported.count == 2)
        #expect(tabs.child.activeTab == 0)
    }

    @Test("dismissChild for a coordinator that is not in the stack does nothing")
    func dismissUnknownChild() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)

        var dismissed = true
        let reported = misuses { dismissed = parent.dismissChild(coordinator: ChildCoordinator()) }

        #expect(!dismissed)
        #expect(reported.count == 1)
        #expect(parent.stack.value.count == 1)
    }

    @Test("focusFirst with a comparator on a route without input does not crash")
    func focusVoidRouteWithComparator() throws {
        let parent = ParentCoordinator()
        parent.route(to: \.child)

        var child: ChildCoordinator?
        let reported = try misuses { child = try parent.focusFirst(\.child, (), comparator: { _, _ in true }) }

        #expect(reported.isEmpty)
        #expect(child?.stack === (parent.stack.value[0].presentable as? ChildCoordinator)?.stack)
    }

    @Test("root with an input switches the root once")
    func rootWithInput() {
        let parent = ParentCoordinator()
        _ = parent.view()

        let first = parent.root(\.childWithInput, 1)
        let second = parent.root(\.childWithInput, 1)

        #expect(first === second)
        #expect(parent.isRoot(\.childWithInput, 1))
        // `parent.root(\.childWithInput)` without an input does not compile.
    }

    @Test("isRoot with an input on a root without input is false")
    func isRootWithInputMismatch() {
        let parent = ParentCoordinator()

        #expect(parent.isRoot(\.start))
        #expect(!parent.isRoot(\.numbered, 1))
        #expect(parent.hasRoot(\.childWithInput, 1) == nil)
    }

    @Test("An initial route without its input shows an empty root")
    func initialRouteWithoutInput() {
        let coordinator = MissingInputCoordinator()

        let reported = misuses { _ = coordinator.view() }

        #expect(reported.count == 1)
        #expect(coordinator.stack.rootItem?.child is AnyView)
    }

    @Test("A router keeps working when nothing else holds its coordinator")
    func routerOutlivesView() {
        var router: NavigationRouter<ParentCoordinator>?
        do {
            let parent = ParentCoordinator()
            _ = parent.view()
            router = parent.stack.router(for: -1)
        }

        router?.route(to: \.screen, 1)
        router?.popLast()

        #expect(router?.coordinator.stack.value.isEmpty == true)
    }

    @Test("A coordinator and its routers do not make a retain cycle")
    func noRetainCycle() {
        weak var weakParent: ParentCoordinator?
        do {
            let parent = ParentCoordinator()
            _ = parent.view()
            parent.route(to: \.screen, 1)
            _ = parent.stack.router(for: -1)
            _ = parent.stack.router(for: 0)
            weakParent = parent
        }

        #expect(weakParent == nil)
    }

    @Test("focusFirst for a route that is not a tab keeps the active tab")
    func focusMissingTab() {
        let tabs = TabsCoordinator()
        _ = tabs.view()
        tabs.child.activeTab = 1

        let reported = misuses { tabs.focusFirst(\.notATab) }

        #expect(reported.count == 1)
        #expect(tabs.child.activeTab == 1)
    }

    @Test("An active tab that does not exist does not crash")
    func activeTabOutOfRange() {
        let tabs = TabsCoordinator()
        _ = tabs.view()

        let reported = misuses {
            tabs.child.activeTab = 7
            tabs.child.activeTab = -1
        }

        #expect(reported.count == 2)
        #expect(tabs.child.activeTab == -1)
    }

    @Test("A path change that adds entries is ignored")
    func pathGrowth() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        let entries = CoordinatorPath.entries(stack: parent.stack, anchor: -1)

        let reported = misuses { CoordinatorPath.apply(entries + entries, to: parent.stack, anchor: -1) }

        #expect(reported.count == 1)
        #expect(parent.stack.value.count == 1)
    }
}

@Suite("canDismissCoordinator")
struct CanDismissTests {
    @Test("A root coordinator cannot be dismissed")
    func root() {
        #expect(!ParentCoordinator().canDismissCoordinator)
    }

    @Test("A pushed child coordinator can be dismissed")
    func pushedChild() {
        let parent = ParentCoordinator()
        let child = parent.route(to: \.child)

        #expect(child.canDismissCoordinator)

        var dismissed = false
        let reported = misuses { dismissed = child.dismissCoordinator() }

        #expect(dismissed && reported.isEmpty)
        #expect(parent.stack.value.isEmpty)
        #expect(!child.canDismissCoordinator)
    }

    @Test("A child coordinator in a pushed ViewWrapperCoordinator can be dismissed")
    func modalWrappedChild() {
        let parent = ParentCoordinator()
        let wrapper = parent.route(to: \.wrappedChild)

        #expect(wrapper.child.canDismissCoordinator)
    }

    @Test("The root coordinator of a tab cannot be dismissed")
    func tabRoot() {
        let tabs = TabsCoordinator()
        _ = tabs.view()

        #expect(!tabs.focusFirst(\.first).child.canDismissCoordinator)
    }

    @Test("A router forwards canDismissCoordinator")
    func router() {
        let parent = ParentCoordinator()
        let child = parent.route(to: \.child)
        _ = child.view()

        #expect(child.stack.router(for: -1)?.canDismissCoordinator == true)
    }
}
