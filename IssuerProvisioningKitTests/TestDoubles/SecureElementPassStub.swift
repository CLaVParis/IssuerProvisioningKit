//
//  SecureElementPassStub.swift
//  IssuerProvisioningKitTests
//

import PassKit
@testable import IssuerProvisioningKit

/// A Wallet pass with any activation state, which `PKSecureElementPass` cannot offer in tests.
struct SecureElementPassStub: SecureElementPassDescribing {
    let primaryAccountIdentifier: String
    let primaryAccountNumberSuffix: String
    let passActivationState: PKSecureElementPass.PassActivationState

    init(id: String, suffix: String, state: PKSecureElementPass.PassActivationState = .activated) {
        primaryAccountIdentifier = id
        primaryAccountNumberSuffix = suffix
        passActivationState = state
    }
}
