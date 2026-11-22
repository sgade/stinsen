import Foundation
import SwiftUI

/// The view of one screen of a `NavigationCoordinatable`: the root (`index == -1`) or one item of the stack.
///
/// The view adds the router of the screen. It also shows the next item of the stack when that item is
/// a modal or full-screen route. A `NavigationHostView` shows pushed items.
///
/// Only the root of a coordinator adds the `customize` modifications, as in a view hierarchy.
/// Other screens get them from the environment. See `NavigationHostView` and `DestinationView`.
struct ScreenView<T: NavigationCoordinatable>: View {
    let coordinator: T
    let stack: CoordinatorStack<T>
    let index: Int

    /// The item that this screen shows, or `nil` for the root.
    ///
    /// The view keeps the item, so that a popped screen can still show during the pop animation.
    let item: NavigationStackItem?

    /// If `true`, the view adds the `customize` modifications of the coordinator.
    let appliesCustomize: Bool

    var body: some View {
        customizedContent
            .modifier(PresentationModifier(stack: stack, index: index, itemID: item?.id))
            .environmentObject(router)
    }

    private var router: NavigationRouter<T.RouterStoreType> {
        stack.router(for: index, coordinator: coordinator)
    }

    private var customizedContent: AnyView {
        appliesCustomize ? AnyView(coordinator.customize(content)) : content
    }

    private var content: AnyView {
        if let item {
            return item.presentable.view()
        }

        guard let root = stack.rootItem else {
            return AnyView(EmptyView())
        }

        // A new identity resets the state of the old root after a root switch.
        return AnyView(root.child.view().id(root.id))
    }
}

/// An item that a screen shows as a sheet or a full-screen cover.
struct PresentedItem: Identifiable {
    let index: Int
    let item: NavigationStackItem

    var id: UUID { item.id }
}

/// Shows the next item of a stack as a sheet or a full-screen cover.
struct PresentationModifier: ViewModifier {
    let stack: AnyCoordinatorStack
    let index: Int
    let itemID: UUID?

    func body(content: Self.Content) -> some View {
        content
            .sheet(item: binding(for: Self.sheetTypes), onDismiss: dismissed) { presented in
                presentedView(presented)
            }
            #if !os(macOS)
            .fullScreenCover(item: binding(for: [.fullScreen]), onDismiss: dismissed) { presented in
                presentedView(presented)
            }
            #endif
    }

    /// macOS has no full-screen cover. There, a full-screen route shows as a sheet.
    #if os(macOS)
    private static let sheetTypes: Set<PresentationType> = [.modal, .modalNonDismissible, .fullScreen]
    #else
    private static let sheetTypes: Set<PresentationType> = [.modal, .modalNonDismissible]
    #endif

    private func binding(for types: Set<PresentationType>) -> Binding<PresentedItem?> {
        let presented = presentedItem(types: types)
        let stack = self.stack
        let index = self.index

        return Binding(
            get: { presented },
            set: { newValue in
                // Pop only if the dismissed item is still the next item. A late call must not pop a newer route.
                guard newValue == nil,
                      let presented,
                      stack.value[safe: index + 1]?.id == presented.id
                else {
                    return
                }

                stack.popTo(index)
            }
        )
    }

    private func presentedItem(types: Set<PresentationType>) -> PresentedItem? {
        // A screen that is not in the stack anymore (for example, during a pop animation) shows nothing.
        if let itemID, stack.value[safe: index]?.id != itemID {
            return nil
        }

        guard let next = stack.value[safe: index + 1], types.contains(next.presentationType) else {
            return nil
        }

        return PresentedItem(index: index + 1, item: next)
    }

    private func dismissed() {
        stack.dismissalAction.removeValue(forKey: index)?()
        // A pop can remove more than one modal level. Then no pushed screen disappears to run the actions.
        stack.runPendingDismissals()
    }

    private func presentedView(_ presented: PresentedItem) -> some View {
        presentedContent(presented)
            // A `.modal(dismissible: false)` route blocks the drag-to-dismiss gesture.
            .interactiveDismissDisabled(!presented.item.presentationType.isModalDismissible)
    }

    @ViewBuilder
    private func presentedContent(_ presented: PresentedItem) -> some View {
        if presented.item.presentable is AnyView {
            // A view gets its own navigation stack, so that it can push routes.
            NavigationHostView(
                stack: stack,
                anchor: presented.index,
                anchorItem: presented.item,
                hidesNavigationBar: true
            )
        } else {
            presented.item.presentable.view()
        }
    }
}
