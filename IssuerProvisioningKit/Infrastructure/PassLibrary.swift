//
//  PassLibrary.swift
//  IssuerProvisioningKit
//

import PassKit

/// The parts of `PKPassLibrary` the framework calls, so tests can stand in for Wallet.
protocol PassLibrary {
    func secureElementPasses() -> [SecureElementPassDescribing]
    func canAddSecureElementPass(primaryAccountIdentifier: String) -> Bool
}

extension PKPassLibrary: PassLibrary {
    func secureElementPasses() -> [SecureElementPassDescribing] {
        passes(of: .secureElement).compactMap(\.secureElementPass)
    }
}
