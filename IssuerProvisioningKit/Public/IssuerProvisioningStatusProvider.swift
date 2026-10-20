//
//  IssuerProvisioningStatusProvider.swift
//  IssuerProvisioningKit
//

import PassKit

/// Answers Wallet's `status(completion:)` call for an issuer extension.
///
/// ```swift
/// override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
///     IssuerProvisioningStatusProvider(lastDigits: ["1234", "5678"], requiresAuthentication: true)
///         .status(completion: completion)
/// }
/// ```
public final class IssuerProvisioningStatusProvider {
    private let lastDigits: [String]
    private let requiresAuthentication: Bool
    private let evaluator: ProvisioningStatusEvaluating
    private let mapper: PassKitStatusMapper

    /// - Parameters:
    ///   - lastDigits: Last digits of every card the issuer could provision.
    ///   - requiresAuthentication: Whether Wallet must show the issuer's sign-in UI first.
    ///   - passLibrary: Wallet access, replaceable to share an existing instance.
    public convenience init(lastDigits: [String],
                            requiresAuthentication: Bool,
                            passLibrary: PKPassLibrary = PKPassLibrary()) {
        let repository = PassKitPassRepository(library: passLibrary)
        self.init(
            lastDigits: lastDigits,
            requiresAuthentication: requiresAuthentication,
            evaluator: ProvisioningStatusEvaluator(
                passProvider: repository,
                remoteEligibilityChecker: repository
            )
        )
    }

    init(lastDigits: [String],
         requiresAuthentication: Bool,
         evaluator: ProvisioningStatusEvaluating,
         mapper: PassKitStatusMapper = PassKitStatusMapper()) {
        self.lastDigits = lastDigits
        self.requiresAuthentication = requiresAuthentication
        self.evaluator = evaluator
        self.mapper = mapper
    }

    /// Calls `completion` synchronously; Wallet ignores answers that take over 100 ms.
    public func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        let availability = evaluator.evaluate(
            lastDigits: lastDigits,
            requiresAuthentication: requiresAuthentication
        )
        completion(mapper.status(from: availability))
    }
}
