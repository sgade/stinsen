import os

private let logger = Logger(subsystem: "Stinsen", category: "Navigation")

/// A navigation request that Stinsen cannot do, for example a dismissal without a presenter.
///
/// Stinsen does not stop the app for such a request. It ignores the request, logs a fault with the
/// subsystem `Stinsen`, and calls `StinsenMisuse.handler`. Set the handler to send the misuse to your
/// crash reporting, to stop in your own Debug builds, or to record an issue in tests:
///
/// ```swift
/// StinsenMisuse.handler = { misuse in
///     assertionFailure(misuse.description)
/// }
/// ```
nonisolated public struct StinsenMisuse: Sendable, CustomStringConvertible {
    /// What Stinsen could not do, and why.
    public let message: String

    /// The Stinsen source file that found the misuse.
    public let file: String

    /// The line in `file`.
    public let line: UInt

    public var description: String {
        "Stinsen: \(message) (\(file):\(line))"
    }

    /// Called on the main actor for each misuse, after Stinsen logs it.
    @MainActor public static var handler: ((StinsenMisuse) -> Void)?
}

/// Reports a navigation request that Stinsen cannot do. See `StinsenMisuse`.
func reportMisuse(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
    let misuse = StinsenMisuse(message: message, file: "\(file)", line: line)
    logger.fault("\(misuse.description, privacy: .public)")
    StinsenMisuse.handler?(misuse)
}
