//
//  SecureElementPassDescribing.swift
//  IssuerProvisioningKit
//

import PassKit

/// The parts of `PKSecureElementPass` the framework reads.
/// Tests cannot create a `PKSecureElementPass` with a chosen state, so they use their own type.
protocol SecureElementPassDescribing {
    var primaryAccountIdentifier: String { get }
    var primaryAccountNumberSuffix: String { get }
    var passActivationState: PKSecureElementPass.PassActivationState { get }
}

extension PKSecureElementPass: SecureElementPassDescribing {}
