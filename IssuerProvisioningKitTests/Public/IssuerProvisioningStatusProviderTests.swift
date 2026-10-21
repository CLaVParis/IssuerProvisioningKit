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
