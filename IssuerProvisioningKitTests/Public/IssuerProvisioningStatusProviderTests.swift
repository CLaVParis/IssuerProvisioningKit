//
//  IssuerProvisioningStatusProviderTests.swift
//  IssuerProvisioningKitTests
//

import PassKit
import Testing
@testable import IssuerProvisioningKit

@Suite("IssuerProvisioningStatusProvider")
struct IssuerProvisioningStatusProviderTests {

    @Test func callsCompletionExactlyOnce() async {
        let sut = makeSUT(evaluator: ProvisioningStatusEvaluatorSpy(result: .noCardAvailable))

        await confirmation(expectedCount: 1) { completionCalled in
            sut.status { _ in completionCalled() }
        }
    }

    @Test func callsCompletionBeforeReturning() {
        let sut = makeSUT(evaluator: ProvisioningStatusEvaluatorSpy(result: .noCardAvailable))
        var didComplete = false

        sut.status { _ in didComplete = true }

        #expect(didComplete)
    }

    @Test func forwardsIssuerInputToEvaluator() {
        let evaluator = ProvisioningStatusEvaluatorSpy(result: .noCardAvailable)
        let sut = makeSUT(lastDigits: ["1111", "2222"], requiresAuthentication: true, evaluator: evaluator)

        sut.status { _ in }

        #expect(evaluator.receivedLastDigits == [["1111", "2222"]])
        #expect(evaluator.receivedRequiresAuthentication == [true])
    }

    @Test func reportsEvaluatorResultToWallet() {
        let result = ProvisioningAvailability(
            passEntriesAvailable: true,
            remotePassEntriesAvailable: false,
            requiresAuthentication: true
        )
        let sut = makeSUT(evaluator: ProvisioningStatusEvaluatorSpy(result: result))
        var received: PKIssuerProvisioningExtensionStatus?

        sut.status { received = $0 }

        #expect(received?.passEntriesAvailable == true)
        #expect(received?.remotePassEntriesAvailable == false)
        #expect(received?.requiresAuthentication == true)
    }

    @Test func combinesRealEvaluatorAndMapper() {
        let evaluator = ProvisioningStatusEvaluator(
            passProvider: SecureElementPassProviderSpy(passes: [.fixture(id: "id-A", suffix: "1111")]),
            remoteEligibilityChecker: RemotePassEligibilityCheckerSpy(eligibleIdentifiers: ["id-A"])
        )
        let sut = makeSUT(lastDigits: ["1111", "9999"], requiresAuthentication: false, evaluator: evaluator)
        var received: PKIssuerProvisioningExtensionStatus?

        sut.status { received = $0 }

        #expect(received?.passEntriesAvailable == true)
        #expect(received?.remotePassEntriesAvailable == true)
        #expect(received?.requiresAuthentication == false)
    }

    /// From the PassKit state to the Wallet status: only a deactivated pass lets the card be added again.
    @Test(arguments: [
        (PKSecureElementPass.PassActivationState.activated, false),
        (.requiresActivation, false),
        (.activating, false),
        (.suspended, false),
        (.deactivated, true)
    ])
    func passStateDecidesIfCardCanBeAdded(_ state: PKSecureElementPass.PassActivationState, canBeAdded: Bool) {
        let library = PassLibrarySpy(passes: [SecureElementPassStub(id: "id-A", suffix: "1234", state: state)])
        let repository = PassKitPassRepository(library: library)
        let sut = makeSUT(evaluator: ProvisioningStatusEvaluator(
            passProvider: repository,
            remoteEligibilityChecker: repository
        ))
        var received: PKIssuerProvisioningExtensionStatus?

        sut.status { received = $0 }

        #expect(received?.passEntriesAvailable == canBeAdded)
    }

    /// The only test that goes through the real `PKPassLibrary`.
    /// Wallet content depends on the machine, so only the call itself is checked.
    @Test func answersWithRealPassLibrary() async {
        let sut = IssuerProvisioningStatusProvider(lastDigits: ["1234"], requiresAuthentication: true)

        await confirmation(expectedCount: 1) { completionCalled in
            sut.status { status in
                #expect(status.requiresAuthentication)
                completionCalled()
            }
        }
    }

    /// Wallet may ask from several threads at once.
    @Test func answersConcurrentCalls() async {
        // Every stored property is a constant, so sharing it across threads is safe.
        nonisolated(unsafe) let sut = IssuerProvisioningStatusProvider(lastDigits: ["1234"], requiresAuthentication: false)

        await confirmation(expectedCount: 100) { completionCalled in
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                sut.status { _ in completionCalled() }
            }
        }
    }

    private func makeSUT(
        lastDigits: [String] = ["1234"],
        requiresAuthentication: Bool = false,
        evaluator: ProvisioningStatusEvaluating
    ) -> IssuerProvisioningStatusProvider {
        IssuerProvisioningStatusProvider(
            lastDigits: lastDigits,
            requiresAuthentication: requiresAuthentication,
            evaluator: evaluator
        )
    }
}

private extension ProvisioningAvailability {
    static let noCardAvailable = ProvisioningAvailability(
        passEntriesAvailable: false,
        remotePassEntriesAvailable: false,
        requiresAuthentication: false
    )
}
