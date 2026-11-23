import Foundation

/// A coordinator that can dismiss the coordinators that it presents.
public protocol ChildDismissable: AnyObject {
    /// Dismisses `coordinator`.
    ///
    /// - Returns: `false` if this coordinator cannot dismiss `coordinator`. Then nothing changes,
    ///   and Stinsen reports a misuse.
    @discardableResult func dismissChild<T: Coordinatable>(coordinator: T, action: (() -> Void)?) -> Bool

    /// `true` if this coordinator can dismiss `coordinator`, for example because `coordinator` is in its stack.
    func canDismissChild<T: Coordinatable>(_ coordinator: T) -> Bool
}
