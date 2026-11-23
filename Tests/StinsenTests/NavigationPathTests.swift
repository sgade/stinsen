import SwiftUI
import Testing
@testable import Stinsen

// MARK: - Test coordinators

final class ChildCoordinator: @MainActor NavigationCoordinatable {
    let stack = CoordinatorStack(initial: \ChildCoordinator.start)

    @Root var start = makeStart
    @Route(.push) var detail = makeDetail

    func makeStart() -> Text { Text("Child") }
    func makeDetail() -> Text { Text("Detail") }
}

final class ParentCoordinator: @MainActor NavigationCoordinatable {
    let stack = CoordinatorStack(initial: \ParentCoordinator.start)

    @Root var start = makeStart
    @Root var childRoot = makeChild
    @Route(.push) var screen = makeScreen
    @Route(.push) var child = makeChild
    @Route(.push) var wrappedChild = makeWrappedChild
    @Root var numbered = makeScreen
    @Root var childWithInput = makeChildWithInput
    @Route(.modal) var sheet = makeStart
    @Route(.modal(dismissible: false)) var lockedSheet = makeStart
    @Route(.fullScreen) var cover = makeStart

    func makeStart() -> Text { Text("Start") }
    func makeScreen(_ number: Int) -> Text { Text("Screen \(number)") }
    func makeChild() -> ChildCoordinator { ChildCoordinator() }
    func makeChildWithInput(_ number: Int) -> ChildCoordinator { ChildCoordinator() }
    func makeWrappedChild() -> ViewWrapperCoordinator<ChildCoordinator, AnyView> {
        ViewWrapperCoordinator(ChildCoordinator()) { AnyView($0) }
    }
}

private func path(of coordinator: ParentCoordinator, anchor: Int = -1) -> [PathEntry] {
    CoordinatorPath.entries(stack: coordinator.stack, anchor: anchor)
}

// MARK: - Path derivation

@Suite("Path derivation")
struct PathDerivationTests {
    @Test("Each push route becomes one path entry")
    func flatPushes() {
        let parent = ParentCoordinator()
        _ = parent.view()

        parent.route(to: \.screen, 1)
        parent.route(to: \.screen, 2)

        let entries = path(of: parent)
        #expect(entries.map(\.index) == [0, 1])
        #expect(entries.allSatisfy { $0.stack === parent.stack && $0.ancestors.isEmpty })
    }

    @Test("A new push of the same route gives a different entry")
    func duplicateRoutes() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        let first = path(of: parent)

        parent.popToRoot()
        parent.route(to: \.screen, 1)
        let second = path(of: parent)

        #expect(first.count == 1 && second.count == 1)
        #expect(first[0] != second[0])
    }

    @Test("The pushes of a pushed child coordinator go into the same path")
    func nestedChild() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        let child = parent.route(to: \.child)
        child.route(to: \.detail)
        parent.route(to: \.screen, 2)

        let entries = path(of: parent)
        #expect(entries.count == 4)
        #expect(entries.map(\.index) == [0, 1, 0, 2])
        #expect(entries[2].stack === child.stack)
        #expect(entries[2].ancestors.map(\.routerID) == [1])
        #expect(entries[2].ancestors.first?.stack === parent.stack)
        #expect(entries[3].stack === parent.stack)
    }

    @Test("The pushes of a child in a ViewWrapperCoordinator go into the same path")
    func wrappedChild() {
        let parent = ParentCoordinator()
        let wrapper = parent.route(to: \.wrappedChild)
        wrapper.child.route(to: \.detail)

        let entries = path(of: parent)
        #expect(entries.count == 2)
        #expect(entries[1].stack === wrapper.child.stack)
    }

    @Test("A NavigationStackCoordinator child keeps its pushes in its own stack")
    func navigationStackCoordinatorChild() {
        let child = ChildCoordinator()
        let wrapper = NavigationStackCoordinator(child)
        child.route(to: \.detail)

        #expect(wrapper.childNavigationStack == nil)
        #expect(CoordinatorPath.entries(stack: child.stack, anchor: -1).count == 1)
    }

    @Test("The pushes of a child coordinator at the root go into the path")
    func rootSwitchChild() {
        let parent = ParentCoordinator()
        let child = parent.root(\.childRoot)
        child.route(to: \.detail)

        let entries = path(of: parent)
        #expect(entries.count == 1)
        #expect(entries[0].stack === child.stack)
        #expect(entries[0].ancestors.map(\.routerID) == [-1])
    }

    @Test("A modal route stops the path; its own host continues it")
    func modalStopsChain() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        parent.route(to: \.sheet)
        parent.route(to: \.screen, 2)
        parent.route(to: \.cover)
        parent.route(to: \.screen, 3)

        #expect(path(of: parent).map(\.index) == [0])
        #expect(path(of: parent, anchor: 1).map(\.index) == [2])
        #expect(path(of: parent, anchor: 3).map(\.index) == [4])
    }

    @Test("A modal that the user cannot drag to dismiss also stops the path")
    func nonDismissibleModal() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        parent.route(to: \.lockedSheet)
        parent.route(to: \.screen, 2)

        let type = parent.stack.value[1].presentationType
        #expect(type == .modalNonDismissible)
        #expect(type.isModal && !type.isModalDismissible)
        #expect(PresentationType.modal(dismissible: true) == .modal)
        #expect(path(of: parent).map(\.index) == [0])
        #expect(path(of: parent, anchor: 1).map(\.index) == [2])
    }

    @Test("A deep link with focusFirst and route gives the full path at once")
    func deepLink() throws {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        parent.route(to: \.screen, 2)
        parent.route(to: \.screen, 3)

        try parent.focusFirst(\.screen, 1)
        let child = parent.route(to: \.child)
        child.route(to: \.detail)

        #expect(path(of: parent).map(\.index) == [0, 1, 0])
    }
}

// MARK: - Path changes from NavigationStack

@Suite("Path changes")
struct PathChangeTests {
    @Test("A back swipe pops one screen")
    func popOne() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        parent.route(to: \.screen, 2)

        let entries = path(of: parent)
        CoordinatorPath.apply(Array(entries.dropLast()), to: parent.stack, anchor: -1)

        #expect(parent.stack.value.count == 1)
    }

    @Test("A multi-pop over a child coordinator pops each stack once")
    func popAcrossChild() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        let child = parent.route(to: \.child)
        child.route(to: \.detail)
        parent.route(to: \.screen, 2)

        // Keep only the first screen and the child root.
        let entries = path(of: parent)
        CoordinatorPath.apply(Array(entries.prefix(2)), to: parent.stack, anchor: -1)

        #expect(parent.stack.value.count == 2)
        #expect(child.stack.value.isEmpty)
        #expect(path(of: parent).count == 2)
    }

    @Test("Pop to root removes the whole path")
    func popToRoot() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        parent.route(to: \.child).route(to: \.detail)

        CoordinatorPath.apply([], to: parent.stack, anchor: -1)

        #expect(parent.stack.value.isEmpty)
        #expect(path(of: parent).isEmpty)
    }

    @Test("A path change in a modal host keeps the modal")
    func popInsideModal() {
        let parent = ParentCoordinator()
        parent.route(to: \.sheet)
        parent.route(to: \.screen, 1)

        CoordinatorPath.apply([], to: parent.stack, anchor: 0)

        #expect(parent.stack.value.count == 1)
        #expect(parent.stack.value[0].presentationType == .modal)
    }
}

// MARK: - Dismissal actions and routers

@Suite("Dismissal actions and routers")
struct DismissalTests {
    @Test("A push dismissal action runs once, after the popped screen disappears")
    func pushDismissal() {
        let parent = ParentCoordinator()
        parent.route(to: \.screen, 1)
        parent.route(to: \.screen, 2)

        var calls = 0
        parent.popToRoot { calls += 1 }

        #expect(calls == 0)
        parent.stack.runPendingDismissals()
        #expect(calls == 1)
        parent.stack.runPendingDismissals()
        #expect(calls == 1)
    }

    @Test("A modal dismissal action stays for the sheet's onDismiss")
    func modalDismissal() {
        let parent = ParentCoordinator()
        parent.route(to: \.sheet)

        parent.popToRoot {}

        #expect(parent.stack.dismissalAction[-1] != nil)
        parent.stack.runPendingDismissals()
        #expect(parent.stack.dismissalAction[-1] != nil)
    }

    @Test("A pop with nothing to pop does not keep its action for a later pop")
    func noStaleAction() {
        let parent = ParentCoordinator()
        var calls = 0
        parent.popToRoot { calls += 1 }

        parent.route(to: \.screen, 1)
        parent.popToRoot()
        parent.stack.runPendingDismissals()

        #expect(calls == 0)
    }

    @Test("A pop removes the routers of the popped screens")
    func routersArePruned() {
        let parent = ParentCoordinator()
        _ = parent.view()
        parent.route(to: \.screen, 1)
        parent.route(to: \.screen, 2)

        let root = parent.stack.router(for: -1)
        let second = parent.stack.router(for: 1)
        #expect(root != nil && second != nil)
        #expect(parent.stack.router(for: 1) === second)

        parent.popLast()

        #expect(parent.stack.routers[1] == nil)
        #expect(parent.stack.router(for: -1) === root)
    }
}
