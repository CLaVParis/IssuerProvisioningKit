//
//  PassKitStatusMapperTests.swift
//  IssuerProvisioningKitTests
//

import Testing
@testable import IssuerProvisioningKit

@Suite("PassKitStatusMapper")
struct PassKitStatusMapperTests {

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

    @Test(arguments: allAvailabilities)
    func copiesEveryField(_ availability: ProvisioningAvailability) {
        let status = PassKitStatusMapper().status(from: availability)

        #expect(status.passEntriesAvailable == availability.passEntriesAvailable)
        #expect(status.remotePassEntriesAvailable == availability.remotePassEntriesAvailable)
        #expect(status.requiresAuthentication == availability.requiresAuthentication)
    }
}
