//
//  SecureElementPassRecord.swift
//  IssuerProvisioningKit
//

/// A payment pass already in Wallet, decoupled from `PKSecureElementPass`.
struct SecureElementPassRecord: Equatable, Sendable {
    let primaryAccountIdentifier: String
    let primaryAccountNumberSuffix: String
    let isDeactivated: Bool
}
