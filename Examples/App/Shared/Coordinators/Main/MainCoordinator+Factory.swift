import Foundation
import SwiftUI
import Stinsen

extension MainCoordinator {
    func makeUnauthenticated() -> NavigationStackCoordinator<UnauthenticatedCoordinator> {
        return NavigationStackCoordinator(UnauthenticatedCoordinator())
    }
    
    func makeAuthenticated(user: User) -> AuthenticatedCoordinator {
        return AuthenticatedCoordinator(user: user)
    }
}
