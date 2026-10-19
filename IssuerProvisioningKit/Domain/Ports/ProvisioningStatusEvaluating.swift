//
//  ProvisioningStatusEvaluating.swift
//  IssuerProvisioningKit
//

/// Decides which of the issuer's cards can be added to this device or the paired Watch.
protocol ProvisioningStatusEvaluating {
    func evaluate(lastDigits: [String], requiresAuthentication: Bool) -> ProvisioningAvailability
}
