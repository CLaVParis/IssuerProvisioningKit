//
//  ProvisioningStatusEvaluatorSpy.swift
//  IssuerProvisioningKitTests
//

@testable import IssuerProvisioningKit

/// Returns a fixed result and records what the provider passed in.
final class ProvisioningStatusEvaluatorSpy: ProvisioningStatusEvaluating {
    private let result: ProvisioningAvailability
    private(set) var receivedLastDigits: [[String]] = []
    private(set) var receivedRequiresAuthentication: [Bool] = []

    init(result: ProvisioningAvailability) {
        self.result = result
    }

    func evaluate(lastDigits: [String], requiresAuthentication: Bool) -> ProvisioningAvailability {
        receivedLastDigits.append(lastDigits)
        receivedRequiresAuthentication.append(requiresAuthentication)
        return result
    }
}
