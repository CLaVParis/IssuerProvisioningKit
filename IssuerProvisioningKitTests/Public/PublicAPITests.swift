//
//  PublicAPITests.swift
//  IssuerProvisioningKitTests
//

import PassKit
import Testing
import IssuerProvisioningKit

/// Uses the framework the way an issuer does, without `@testable`.
/// This file stops compiling if anything an issuer needs is no longer public.
@Suite("Public API")
struct PublicAPITests {

    /// The shortest setup an issuer can write.
    @Test func worksWithDefaultPassLibrary() {
        let provider = IssuerProvisioningStatusProvider(lastDigits: ["1234"], requiresAuthentication: true)
        var received: PKIssuerProvisioningExtensionStatus?

        provider.status { received = $0 }

        #expect(received?.requiresAuthentication == true)
    }

    /// An issuer can pass in a `PKPassLibrary` it already holds.
    @Test func acceptsAnExistingPassLibrary() {
        let provider = IssuerProvisioningStatusProvider(
            lastDigits: ["1234"],
            requiresAuthentication: false,
            passLibrary: PKPassLibrary()
        )
        var received: PKIssuerProvisioningExtensionStatus?

        provider.status { received = $0 }

        #expect(received?.requiresAuthentication == false)
    }

    /// Wallet's completion handler can be passed straight through,
    /// as in `PKIssuerProvisioningExtensionHandler.status(completion:)`.
    @Test func passesWalletCompletionHandlerThrough() async {
        await confirmation(expectedCount: 1) { completionCalled in
            let walletCompletion: (PKIssuerProvisioningExtensionStatus) -> Void = { _ in completionCalled() }

            IssuerProvisioningStatusProvider(lastDigits: ["1234"], requiresAuthentication: false)
                .status(completion: walletCompletion)
        }
    }
}
