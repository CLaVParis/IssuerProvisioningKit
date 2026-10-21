//
//  PassLibrarySpy.swift
//  IssuerProvisioningKitTests
//

@testable import IssuerProvisioningKit

/// Stands in for `PKPassLibrary` and records which passes the Watch check was asked about.
final class PassLibrarySpy: PassLibrary {
    private let passes: [SecureElementPassDescribing]
    private let canAddToWatch: Bool
    private(set) var requestedIdentifiers: [String] = []

    init(passes: [SecureElementPassDescribing] = [], canAddToWatch: Bool = false) {
        self.passes = passes
        self.canAddToWatch = canAddToWatch
    }

    func secureElementPasses() -> [SecureElementPassDescribing] {
        passes
    }

    func canAddSecureElementPass(primaryAccountIdentifier: String) -> Bool {
        requestedIdentifiers.append(primaryAccountIdentifier)
        return canAddToWatch
    }
}
