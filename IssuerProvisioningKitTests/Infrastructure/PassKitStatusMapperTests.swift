//
//  PassKitStatusMapperTests.swift
//  IssuerProvisioningKitTests
//

import Testing
@testable import IssuerProvisioningKit

@Suite("PassKitStatusMapper")
struct PassKitStatusMapperTests {

    /// Every combination of the three flags.
    static let allAvailabilities: [ProvisioningAvailability] = [false, true].flatMap { onDevice in
        [false, true].flatMap { onWatch in
            [false, true].map { requiresAuthentication in
                ProvisioningAvailability(
                    passEntriesAvailable: onDevice,
                    remotePassEntriesAvailable: onWatch,
                    requiresAuthentication: requiresAuthentication
                )
            }
        }
    }

    /// Each flag lands in the matching PassKit property.
    /// All combinations are used, because a swap only shows when two flags differ.
    @Test(arguments: allAvailabilities)
    func copiesEveryField(_ availability: ProvisioningAvailability) {
        let status = PassKitStatusMapper().status(from: availability)

        #expect(status.passEntriesAvailable == availability.passEntriesAvailable)
        #expect(status.remotePassEntriesAvailable == availability.remotePassEntriesAvailable)
        #expect(status.requiresAuthentication == availability.requiresAuthentication)
    }
}
