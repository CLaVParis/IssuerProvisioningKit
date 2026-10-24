//
//  PassKitPassRepositoryTests.swift
//  IssuerProvisioningKitTests
//

import PassKit
import Testing
@testable import IssuerProvisioningKit

@Suite("PassKitPassRepository")
struct PassKitPassRepositoryTests {

    /// The one state the brief treats as absent.
    @Test func deactivatedPassIsMarkedDeactivated() {
        let sut = makeSUT(passes: [SecureElementPassStub(id: "id-A", suffix: "1234", state: .deactivated)])

        #expect(sut.secureElementPasses().first?.isDeactivated == true)
    }

    /// The brief only treats a deactivated pass as absent, so every other state stays present.
    @Test(arguments: [
        PKSecureElementPass.PassActivationState.activated,
        .requiresActivation,
        .activating,
        .suspended
    ])
    func otherStatesAreNotDeactivated(_ state: PKSecureElementPass.PassActivationState) {
        let sut = makeSUT(passes: [SecureElementPassStub(id: "id-A", suffix: "1234", state: state)])

        #expect(sut.secureElementPasses().first?.isDeactivated == false)
    }

    /// Identifier and suffix are copied as is, not swapped or changed.
    @Test func copiesIdentifierAndSuffix() {
        let sut = makeSUT(passes: [SecureElementPassStub(id: "id-A", suffix: "1234")])

        #expect(sut.secureElementPasses() == [
            SecureElementPassRecord(
                primaryAccountIdentifier: "id-A",
                primaryAccountNumberSuffix: "1234",
                isDeactivated: false
            )
        ])
    }

    /// No pass is dropped and the order is kept.
    @Test func keepsEveryPassInOrder() {
        let sut = makeSUT(passes: [
            SecureElementPassStub(id: "id-A", suffix: "1111"),
            SecureElementPassStub(id: "id-B", suffix: "2222"),
            SecureElementPassStub(id: "id-C", suffix: "3333")
        ])

        #expect(sut.secureElementPasses().map(\.primaryAccountIdentifier) == ["id-A", "id-B", "id-C"])
    }

    /// An empty Wallet gives an empty list.
    @Test func emptyWalletGivesNoRecord() {
        let sut = makeSUT(passes: [])

        #expect(sut.secureElementPasses().isEmpty)
    }

    /// PassKit receives the identifier the Watch check was given.
    @Test func watchCheckSendsPassIdentifier() {
        let library = PassLibrarySpy()
        let sut = PassKitPassRepository(library: library)

        _ = sut.canAddToRemoteDevice(primaryAccountIdentifier: "id-A")

        #expect(library.requestedIdentifiers == ["id-A"])
    }

    /// PassKit's answer is returned unchanged.
    @Test(arguments: [true, false])
    func watchCheckReturnsLibraryAnswer(_ canAddToWatch: Bool) {
        let sut = PassKitPassRepository(library: PassLibrarySpy(canAddToWatch: canAddToWatch))

        #expect(sut.canAddToRemoteDevice(primaryAccountIdentifier: "id-A") == canAddToWatch)
    }

    private func makeSUT(passes: [SecureElementPassDescribing]) -> PassKitPassRepository {
        PassKitPassRepository(library: PassLibrarySpy(passes: passes))
    }
}
