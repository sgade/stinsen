import Foundation
import SwiftUI
import Stinsen

extension TestbedEnvironmentObjectCoordinator {
    @ViewBuilder func makePushScreen() -> some View {
        TestbedEnvironmentObjectScreen()
    }
    
    @ViewBuilder func makeModalScreen() -> some View {
        // Stinsen shows a modal view in its own NavigationStack, so the screen does not add one.
        TestbedEnvironmentObjectScreen()
    }
    
    func makePushCoordinator() -> TestbedEnvironmentObjectCoordinator {
        return TestbedEnvironmentObjectCoordinator()
    }
    
    func makeModalCoordinator() -> NavigationStackCoordinator<TestbedEnvironmentObjectCoordinator> {
        return NavigationStackCoordinator(TestbedEnvironmentObjectCoordinator())
    }
    
    @ViewBuilder func makeStart() -> some View {
        TestbedEnvironmentObjectScreen()
    }
}
