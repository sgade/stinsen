import Foundation
import SwiftUI

struct TabCoordinatableView<T: TabCoordinatable, U: View>: View {
    private var coordinator: T
    private let router: TabRouter<T>
    @Bindable var child: TabChild
    private var customize: (AnyView) -> U
    private var views: [AnyView]

    var body: some View {
        customize(AnyView(tabView))
            .environmentObject(router)
    }

    @ViewBuilder
    private var tabView: some View {
        if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, *) {
            TabView(selection: $child.activeTab) {
                ForEach(Array(views.enumerated()), id: \.offset) { view in
                    Tab(value: view.offset) {
                        view.element
                    } label: {
                        tabItem(at: view.offset)
                    }
                }
            }
        } else {
            TabView(selection: $child.activeTab) {
                ForEach(Array(views.enumerated()), id: \.offset) { view in
                    view.element
                        .tabItem {
                            tabItem(at: view.offset)
                        }
                        .tag(view.offset)
                }
            }
        }
    }

    private func tabItem(at offset: Int) -> AnyView {
        coordinator.child.allItems[offset].tabItem(offset == child.activeTab)
    }

    init(paths: [AnyKeyPath], coordinator: T, customize: @escaping (AnyView) -> U) {
        self.coordinator = coordinator

        self.router = TabRouter(coordinator: coordinator.routerStorable)
        RouterStore.shared.store(router: router)
        self.customize = customize
        self.child = coordinator.child

        if coordinator.child.allItems == nil {
            coordinator.setupAllTabs()
        }

        self.views = coordinator.child.allItems.map {
            $0.presentable.view()
        }
    }
}
