//
//  PassKitPassRepository.swift
//  IssuerProvisioningKit
//

import PassKit

/// Reads Wallet through `PKPassLibrary` and converts passes into domain records.
final class PassKitPassRepository: SecureElementPassProviding, RemotePassEligibilityChecking {
    private let library: PKPassLibrary

    init(library: PKPassLibrary) {
        self.library = library
    }

    func secureElementPasses() -> [SecureElementPassRecord] {
        library.passes(of: .secureElement)
            .compactMap(\.secureElementPass)
            .map { pass in
                SecureElementPassRecord(
                    primaryAccountIdentifier: pass.primaryAccountIdentifier,
                    primaryAccountNumberSuffix: pass.primaryAccountNumberSuffix,
                    isDeactivated: pass.passActivationState == .deactivated
                )
            }
    }

    func canAddToRemoteDevice(primaryAccountIdentifier: String) -> Bool {
        library.canAddSecureElementPass(primaryAccountIdentifier: primaryAccountIdentifier)
    }
}
