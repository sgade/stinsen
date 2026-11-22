import Foundation
import SwiftUI
import Stinsen

extension AuthenticatedCoordinator {
    func makeTestbed()  -> NavigationStackCoordinator<TestbedEnvironmentObjectCoordinator> {
        return NavigationStackCoordinator(TestbedEnvironmentObjectCoordinator())
    }
    
    @ViewBuilder func makeTestbedTab(isActive: Bool) -> some View {
        Image(systemName: "bed.double" + (isActive ? ".fill" : ""))
        Text("Testbed")
    }
    
    func onTestbedTapped(_ isRepeat: Bool, coordinator: NavigationStackCoordinator<TestbedEnvironmentObjectCoordinator>) {
        if isRepeat {
            coordinator.child.popToRoot()
        }
    }

    func makeHome() -> HomeCoordinator {
        return HomeCoordinator(todosStore: todosStore)
    }
    
    @ViewBuilder func makeHomeTab(isActive: Bool) -> some View {
        Image(systemName: "house" + (isActive ? ".fill" : ""))
        Text("Home")
    }
    
    func makeTodos() -> NavigationStackCoordinator<TodosCoordinator> {
        return NavigationStackCoordinator(TodosCoordinator(todosStore: todosStore))
    }
    
    @ViewBuilder func makeTodosTab(isActive: Bool) -> some View {
        Image(systemName: "folder" + (isActive ? ".fill" : ""))
        Text("Todos")
    }
    
    func makeProfile() -> NavigationStackCoordinator<ProfileCoordinator> {
        return NavigationStackCoordinator(ProfileCoordinator(user: user))
    }
    
    @ViewBuilder func makeProfileTab(isActive: Bool) -> some View {
        Image(systemName: "person.crop.circle" + (isActive ? ".fill" : ""))
        Text("Profile")
    }
}
