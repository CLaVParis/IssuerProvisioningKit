//
//  SecureElementPassRecord+Fixture.swift
//  IssuerProvisioningKitTests
//

@testable import IssuerProvisioningKit

extension SecureElementPassRecord {
    static func fixture(id: String, suffix: String, isDeactivated: Bool = false) -> Self {
        SecureElementPassRecord(
            primaryAccountIdentifier: id,
            primaryAccountNumberSuffix: suffix,
            isDeactivated: isDeactivated
        )
    }
}
