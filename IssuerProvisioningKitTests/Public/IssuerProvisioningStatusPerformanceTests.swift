//
//  IssuerProvisioningStatusPerformanceTests.swift
//  IssuerProvisioningKitTests
//

import XCTest
@testable import IssuerProvisioningKit

/// Wallet ignores `status(completion:)` answers that take more than 100 ms.
final class IssuerProvisioningStatusPerformanceTests: XCTestCase {

    private let walletTimeout: TimeInterval = 0.1

    /// A usual Wallet: 20 passes and 5 issuer cards.
    func test_status_completesWithin100ms_forTypicalWallet() {
        let sut = makeSUT(passCount: 20, lastDigitsCount: 5)

        XCTAssertEqual(waitForCompletion(of: sut, within: walletTimeout), .completed)
    }

    /// Every card is on the device and none can go to the Watch, so no early exit happens.
    func test_status_completesWithin100ms_forWorstCaseWithTenThousandCards() {
        let sut = makeSUT(passCount: 10_000, lastDigitsCount: 10_000)

        XCTAssertEqual(waitForCompletion(of: sut, within: walletTimeout), .completed)
    }

    /// Reports timing in Xcode only. No baseline is stored, since baselines are tied to one Mac.
    func test_status_performance_forWorstCaseWithTenThousandCards() {
        let sut = makeSUT(passCount: 10_000, lastDigitsCount: 10_000)

        measure {
            sut.status { _ in }
        }
    }

    /// Proves the 100 ms check above can fail, so its passing result is meaningful.
    func test_waitForCompletion_reportsTimeout_whenStatusIsSlow() {
        let sut = IssuerProvisioningStatusProvider(
            lastDigits: ["1234"],
            requiresAuthentication: false,
            evaluator: SlowProvisioningStatusEvaluatorStub(delay: 0.2)
        )

        XCTAssertEqual(waitForCompletion(of: sut, within: walletTimeout), .timedOut)
    }

    // MARK: - Helpers

    /// `status` runs on a background queue: it calls `completion` synchronously,
    /// so calling it here would finish before the wait starts and always succeed.
    private func waitForCompletion(
        of sut: IssuerProvisioningStatusProvider,
        within timeout: TimeInterval
    ) -> XCTWaiter.Result {
        let completed = XCTestExpectation(description: "status completion called")
        let returned = XCTestExpectation(description: "status returned")

        DispatchQueue.global(qos: .userInitiated).async {
            sut.status { _ in completed.fulfill() }
            returned.fulfill()
        }

        // XCTWaiter reports a timeout as a result instead of failing the test.
        let result = XCTWaiter().wait(for: [completed], timeout: timeout)
        // Keeps a slow call from outliving the test.
        _ = XCTWaiter().wait(for: [returned], timeout: 5)
        return result
    }

    /// Every lastDigits value matches a pass and no pass can go to the Watch,
    /// so nothing ends the loop early.
    private func makeSUT(passCount: Int, lastDigitsCount: Int) -> IssuerProvisioningStatusProvider {
        // Four digits, like a real suffix: 0 becomes "0000".
        let suffix = { (index: Int) in String(format: "%04d", index) }
        let passes = (0..<passCount).map { SecureElementPassRecord.fixture(id: "id-\($0)", suffix: suffix($0)) }
        let lastDigits = (0..<lastDigitsCount).map { suffix($0 % max(passCount, 1)) }
        let evaluator = ProvisioningStatusEvaluator(
            passProvider: SecureElementPassProviderSpy(passes: passes),
            remoteEligibilityChecker: RemotePassEligibilityCheckerSpy(eligibleIdentifiers: [])
        )
        return IssuerProvisioningStatusProvider(
            lastDigits: lastDigits,
            requiresAuthentication: false,
            evaluator: evaluator
        )
    }
}
