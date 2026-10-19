//
//  RemotePassEligibilityChecking.swift
//  IssuerProvisioningKit
//

/// Tells whether a pass can still be added to the paired Apple Watch.
protocol RemotePassEligibilityChecking {
    func canAddToRemoteDevice(primaryAccountIdentifier: String) -> Bool
}
