//
//  SlowProvisioningStatusEvaluatorStub.swift
//  IssuerProvisioningKitTests
//

import Foundation
@testable import IssuerProvisioningKit

/// Blocks for `delay` before answering, to prove the 100 ms check can fail.
struct SlowProvisioningStatusEvaluatorStub: ProvisioningStatusEvaluating {
    let delay: TimeInterval

    func evaluate(lastDigits: [String], requiresAuthentication: Bool) -> ProvisioningAvailability {
        Thread.sleep(forTimeInterval: delay)
        return ProvisioningAvailability(
            passEntriesAvailable: false,
            remotePassEntriesAvailable: false,
            requiresAuthentication: requiresAuthentication
        )
    }
}
