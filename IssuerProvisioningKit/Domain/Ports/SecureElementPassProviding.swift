//
//  SecureElementPassProviding.swift
//  IssuerProvisioningKit
//

/// Source of the payment passes already in Wallet on this device.
protocol SecureElementPassProviding {
    func secureElementPasses() -> [SecureElementPassRecord]
}
