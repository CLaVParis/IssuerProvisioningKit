//
//  RemotePassEligibilityCheckerSpy.swift
//  IssuerProvisioningKitTests
//

@testable import IssuerProvisioningKit

/// Stands in for the Apple Watch check and records which passes were asked about.
final class RemotePassEligibilityCheckerSpy: RemotePassEligibilityChecking {
    private let eligibleIdentifiers: Set<String>
    private(set) var requestedIdentifiers: [String] = []

    init(eligibleIdentifiers: Set<String> = []) {
        self.eligibleIdentifiers = eligibleIdentifiers
    }

    func canAddToRemoteDevice(primaryAccountIdentifier: String) -> Bool {
        requestedIdentifiers.append(primaryAccountIdentifier)
        return eligibleIdentifiers.contains(primaryAccountIdentifier)
    }
}
