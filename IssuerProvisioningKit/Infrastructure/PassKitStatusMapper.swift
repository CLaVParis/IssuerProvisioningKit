//
//  PassKitStatusMapper.swift
//  IssuerProvisioningKit
//

import PassKit

/// Copies each field of `ProvisioningAvailability` into `PKIssuerProvisioningExtensionStatus`.
struct PassKitStatusMapper {
    func status(from availability: ProvisioningAvailability) -> PKIssuerProvisioningExtensionStatus {
        let status = PKIssuerProvisioningExtensionStatus()
        status.passEntriesAvailable = availability.passEntriesAvailable
        status.remotePassEntriesAvailable = availability.remotePassEntriesAvailable
        status.requiresAuthentication = availability.requiresAuthentication
        return status
    }
}
