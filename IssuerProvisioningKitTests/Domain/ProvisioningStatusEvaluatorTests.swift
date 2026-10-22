//
//  ProvisioningStatusEvaluatorTests.swift
//  IssuerProvisioningKitTests
//

import Testing
@testable import IssuerProvisioningKit

@Suite("ProvisioningStatusEvaluator")
struct ProvisioningStatusEvaluatorTests {

    struct Scenario: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let passes: [SecureElementPassRecord]
        let watchEligibleIdentifiers: Set<String>
        let lastDigits: [String]
        let expectedOnDevice: Bool
        let expectedOnWatch: Bool
    }

    static let scenarios: [Scenario] = [
        Scenario(
            testDescription: "No pass in Wallet: card can be added to the device",
            passes: [],
            watchEligibleIdentifiers: [],
            lastDigits: ["1234"],
            expectedOnDevice: true,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Card missing from Wallet: card can be added to the device",
            passes: [.fixture(id: "id-A", suffix: "1111")],
            watchEligibleIdentifiers: ["id-A"],
            lastDigits: ["1234"],
            expectedOnDevice: true,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Card on device and addable to Watch",
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: ["id-A"],
            lastDigits: ["1234"],
            expectedOnDevice: false,
            expectedOnWatch: true
        ),
        Scenario(
            testDescription: "Card on device and already on Watch",
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: [],
            lastDigits: ["1234"],
            expectedOnDevice: false,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Every card on device and already on Watch",
            passes: [
                .fixture(id: "id-A", suffix: "1111"),
                .fixture(id: "id-B", suffix: "2222")
            ],
            watchEligibleIdentifiers: [],
            lastDigits: ["1111", "2222"],
            expectedOnDevice: false,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Deactivated pass counts as absent",
            passes: [.fixture(id: "id-A", suffix: "1234", isDeactivated: true)],
            watchEligibleIdentifiers: ["id-A"],
            lastDigits: ["1234"],
            expectedOnDevice: true,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Every card deactivated: all can be added to the device",
            passes: [
                .fixture(id: "id-A", suffix: "1111", isDeactivated: true),
                .fixture(id: "id-B", suffix: "2222", isDeactivated: true)
            ],
            watchEligibleIdentifiers: ["id-A", "id-B"],
            lastDigits: ["1111", "2222"],
            expectedOnDevice: true,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Reissued card: old pass deactivated, new pass active",
            passes: [
                .fixture(id: "id-old", suffix: "1234", isDeactivated: true),
                .fixture(id: "id-new", suffix: "1234")
            ],
            watchEligibleIdentifiers: ["id-new"],
            lastDigits: ["1234"],
            expectedOnDevice: false,
            expectedOnWatch: true
        ),
        Scenario(
            testDescription: "Several active passes share a suffix, one is addable to Watch",
            passes: [
                .fixture(id: "id-A", suffix: "1234"),
                .fixture(id: "id-B", suffix: "1234")
            ],
            watchEligibleIdentifiers: ["id-B"],
            lastDigits: ["1234"],
            expectedOnDevice: false,
            expectedOnWatch: true
        ),
        Scenario(
            testDescription: "Mixed cards: one missing, one addable to Watch",
            passes: [
                .fixture(id: "id-A", suffix: "1111"),
                .fixture(id: "id-B", suffix: "2222")
            ],
            watchEligibleIdentifiers: ["id-B"],
            lastDigits: ["1111", "2222", "9999"],
            expectedOnDevice: true,
            expectedOnWatch: true
        ),
        Scenario(
            testDescription: "No card from the issuer",
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: ["id-A"],
            lastDigits: [],
            expectedOnDevice: false,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Suffix must match exactly",
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: ["id-A"],
            lastDigits: [" 1234"],
            expectedOnDevice: true,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Empty lastDigits entry is not reported as an addable card",
            passes: [],
            watchEligibleIdentifiers: [],
            lastDigits: [""],
            expectedOnDevice: false,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Empty lastDigits entry is ignored next to a real card",
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: [],
            lastDigits: ["", "1234"],
            expectedOnDevice: false,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Leading zero is kept, so 0123 matches",
            passes: [.fixture(id: "id-A", suffix: "0123")],
            watchEligibleIdentifiers: [],
            lastDigits: ["0123"],
            expectedOnDevice: false,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Shorter lastDigits do not match a longer suffix",
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: [],
            lastDigits: ["234"],
            expectedOnDevice: true,
            expectedOnWatch: false
        ),
        // Known limit of suffix matching, see Open Discussion in the README.
        Scenario(
            testDescription: "Two issuer cards sharing a suffix both match the one pass in Wallet",
            passes: [.fixture(id: "id-credit", suffix: "1234")],
            watchEligibleIdentifiers: [],
            lastDigits: ["1234", "1234"],
            expectedOnDevice: false,
            expectedOnWatch: false
        ),
        Scenario(
            testDescription: "Reissued card: only the deactivated old pass is addable to Watch",
            passes: [
                .fixture(id: "id-old", suffix: "1234", isDeactivated: true),
                .fixture(id: "id-new", suffix: "1234")
            ],
            watchEligibleIdentifiers: ["id-old"],
            lastDigits: ["1234"],
            expectedOnDevice: false,
            expectedOnWatch: false
        )
    ]

    @Test(arguments: scenarios)
    func availability(_ scenario: Scenario) {
        let (sut, _, _) = makeSUT(
            passes: scenario.passes,
            watchEligibleIdentifiers: scenario.watchEligibleIdentifiers
        )

        let result = sut.evaluate(lastDigits: scenario.lastDigits, requiresAuthentication: false)

        #expect(result == ProvisioningAvailability(
            passEntriesAvailable: scenario.expectedOnDevice,
            remotePassEntriesAvailable: scenario.expectedOnWatch,
            requiresAuthentication: false
        ))
    }

    @Test(arguments: [true, false])
    func requiresAuthenticationIsPassedThrough(_ requiresAuthentication: Bool) {
        let (sut, _, _) = makeSUT(passes: [], watchEligibleIdentifiers: [])

        let result = sut.evaluate(lastDigits: ["1234"], requiresAuthentication: requiresAuthentication)

        #expect(result.requiresAuthentication == requiresAuthentication)
        #expect(result.passEntriesAvailable)
        #expect(!result.remotePassEntriesAvailable)
    }

    @Test func watchCheckUsesIdentifierOfMatchedPass() {
        let violet = SecureElementPassRecord.fixture(id: "id-violet", suffix: "4242")
        let (sut, _, watchChecker) = makeSUT(
            passes: [violet, .fixture(id: "id-other", suffix: "1111")],
            watchEligibleIdentifiers: []
        )

        _ = sut.evaluate(lastDigits: [violet.primaryAccountNumberSuffix], requiresAuthentication: false)

        #expect(watchChecker.requestedIdentifiers == [violet.primaryAccountIdentifier])
    }

    @Test func watchIsNotAskedAboutCardsAbsentFromDevice() {
        let (sut, _, watchChecker) = makeSUT(
            passes: [.fixture(id: "id-A", suffix: "2222", isDeactivated: true)],
            watchEligibleIdentifiers: ["id-A"]
        )

        _ = sut.evaluate(lastDigits: ["2222", "9999"], requiresAuthentication: false)

        #expect(watchChecker.requestedIdentifiers.isEmpty)
    }

    @Test func watchIsNotAskedAgainOnceAnswerIsKnown() {
        let (sut, _, watchChecker) = makeSUT(
            passes: [.fixture(id: "id-A", suffix: "1111"), .fixture(id: "id-B", suffix: "2222")],
            watchEligibleIdentifiers: ["id-A", "id-B"]
        )

        _ = sut.evaluate(lastDigits: ["1111", "2222"], requiresAuthentication: false)

        #expect(watchChecker.requestedIdentifiers == ["id-A"])
    }

    @Test func passesAreReadOnce() {
        let (sut, passProvider, _) = makeSUT(
            passes: [.fixture(id: "id-A", suffix: "1111")],
            watchEligibleIdentifiers: []
        )

        _ = sut.evaluate(lastDigits: ["1111", "2222", "3333"], requiresAuthentication: false)

        #expect(passProvider.callCount == 1)
    }

    @Test func walletIsNotReadWithoutLastDigits() {
        let (sut, passProvider, _) = makeSUT(
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: []
        )

        _ = sut.evaluate(lastDigits: [], requiresAuthentication: false)

        #expect(passProvider.callCount == 0)
    }

    @Test func duplicateLastDigitsAreCheckedOnce() {
        let (sut, _, watchChecker) = makeSUT(
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: []
        )

        _ = sut.evaluate(lastDigits: ["1234", "1234"], requiresAuthentication: false)

        #expect(watchChecker.requestedIdentifiers == ["id-A"])
    }

    /// The early exit must not let the order of `lastDigits` change the answer.
    @Test(arguments: [["1234", "5678"], ["5678", "1234"]])
    func resultDoesNotDependOnOrder(_ lastDigits: [String]) {
        let (sut, _, _) = makeSUT(
            passes: [.fixture(id: "id-A", suffix: "1234")],
            watchEligibleIdentifiers: ["id-A"]
        )

        let result = sut.evaluate(lastDigits: lastDigits, requiresAuthentication: false)

        #expect(result.passEntriesAvailable)
        #expect(result.remotePassEntriesAvailable)
    }

    @Test func walletIsReadAgainOnEveryCall() {
        let (sut, passProvider, _) = makeSUT(passes: [], watchEligibleIdentifiers: [])
        let before = sut.evaluate(lastDigits: ["1234"], requiresAuthentication: false)

        passProvider.passes = [.fixture(id: "id-A", suffix: "1234")]
        let after = sut.evaluate(lastDigits: ["1234"], requiresAuthentication: false)

        #expect(before.passEntriesAvailable)
        #expect(!after.passEntriesAvailable)
    }

    private func makeSUT(
        passes: [SecureElementPassRecord],
        watchEligibleIdentifiers: Set<String>
    ) -> (ProvisioningStatusEvaluator, SecureElementPassProviderSpy, RemotePassEligibilityCheckerSpy) {
        let passProvider = SecureElementPassProviderSpy(passes: passes)
        let watchChecker = RemotePassEligibilityCheckerSpy(eligibleIdentifiers: watchEligibleIdentifiers)
        let sut = ProvisioningStatusEvaluator(
            passProvider: passProvider,
            remoteEligibilityChecker: watchChecker
        )
        return (sut, passProvider, watchChecker)
    }
}
