//
//  PassKitPassRepository.swift
//  IssuerProvisioningKit
//

import PassKit

/// Reads Wallet through `PKPassLibrary` and converts passes into domain records.
final class PassKitPassRepository: SecureElementPassProviding, RemotePassEligibilityChecking {
    private let library: PassLibrary

    init(library: PassLibrary) {
        self.library = library
    }

    func secureElementPasses() -> [SecureElementPassRecord] {
        library.secureElementPasses().map { pass in
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
