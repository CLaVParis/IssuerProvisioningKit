//
//  ProvisioningStatusEvaluator.swift
//  IssuerProvisioningKit
//

/// Compares the issuer's `lastDigits` with the passes already in Wallet.
struct ProvisioningStatusEvaluator: ProvisioningStatusEvaluating {
    private let passProvider: SecureElementPassProviding
    private let remoteEligibilityChecker: RemotePassEligibilityChecking

    init(passProvider: SecureElementPassProviding,
         remoteEligibilityChecker: RemotePassEligibilityChecking) {
        self.passProvider = passProvider
        self.remoteEligibilityChecker = remoteEligibilityChecker
    }

    func evaluate(lastDigits: [String], requiresAuthentication: Bool) -> ProvisioningAvailability {
        // Passes are read once and indexed by suffix, so each lookup is O(1) on average.
        // Total O(n + m) for n passes and m lastDigits, instead of O(n × m) nested loops.
        // A deactivated pass counts as absent, so it is dropped before matching.
        // Grouped because a reissued card can share its suffix with an older pass.
        let activePassesBySuffix = Dictionary(
            grouping: passProvider.secureElementPasses().filter { !$0.isDeactivated },
            by: \.primaryAccountNumberSuffix
        )

        var passEntriesAvailable = false
        var remotePassEntriesAvailable = false

        for digits in lastDigits {
            if let matchingPasses = activePassesBySuffix[digits] {
                // Each check goes through PassKit, so skip it once the Watch answer is known.
                if !remotePassEntriesAvailable {
                    remotePassEntriesAvailable = matchingPasses.contains {
                        remoteEligibilityChecker.canAddToRemoteDevice(
                            primaryAccountIdentifier: $0.primaryAccountIdentifier
                        )
                    }
                }
            } else {
                passEntriesAvailable = true
            }

            // Both answers are final, the remaining cards cannot change them.
            if passEntriesAvailable && remotePassEntriesAvailable { break }
        }

        return ProvisioningAvailability(
            passEntriesAvailable: passEntriesAvailable,
            remotePassEntriesAvailable: remotePassEntriesAvailable,
            requiresAuthentication: requiresAuthentication
        )
    }
}
