//
//  ProvisioningAvailability.swift
//  IssuerProvisioningKit
//

/// Result reported to Wallet, decoupled from `PKIssuerProvisioningExtensionStatus`.
struct ProvisioningAvailability: Equatable, Sendable {
    let passEntriesAvailable: Bool
    let remotePassEntriesAvailable: Bool
    let requiresAuthentication: Bool
}
