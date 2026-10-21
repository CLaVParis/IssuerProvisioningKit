//
//  SecureElementPassProviderSpy.swift
//  IssuerProvisioningKitTests
//

@testable import IssuerProvisioningKit

/// Stands in for the passes in Wallet and counts how often they are read.
final class SecureElementPassProviderSpy: SecureElementPassProviding {
    private let passes: [SecureElementPassRecord]
    private(set) var callCount = 0

    init(passes: [SecureElementPassRecord]) {
        self.passes = passes
    }

    func secureElementPasses() -> [SecureElementPassRecord] {
        callCount += 1
        return passes
    }
}
