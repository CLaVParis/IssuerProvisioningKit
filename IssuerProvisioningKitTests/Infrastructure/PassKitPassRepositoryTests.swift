//
//  PassKitPassRepositoryTests.swift
//  IssuerProvisioningKitTests
//

import PassKit
import Testing
@testable import IssuerProvisioningKit

@Suite("PassKitPassRepository")
struct PassKitPassRepositoryTests {

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

    @Test func keepsEveryPassInOrder() {
        let sut = makeSUT(passes: [
            SecureElementPassStub(id: "id-A", suffix: "1111"),
            SecureElementPassStub(id: "id-B", suffix: "2222"),
            SecureElementPassStub(id: "id-C", suffix: "3333")
        ])

        #expect(sut.secureElementPasses().map(\.primaryAccountIdentifier) == ["id-A", "id-B", "id-C"])
    }

    @Test func emptyWalletGivesNoRecord() {
        let sut = makeSUT(passes: [])

        #expect(sut.secureElementPasses().isEmpty)
    }

    @Test func watchCheckSendsPassIdentifier() {
        let library = PassLibrarySpy()
        let sut = PassKitPassRepository(library: library)

        _ = sut.canAddToRemoteDevice(primaryAccountIdentifier: "id-A")

        #expect(library.requestedIdentifiers == ["id-A"])
    }

    @Test(arguments: [true, false])
    func watchCheckReturnsLibraryAnswer(_ canAddToWatch: Bool) {
        let sut = PassKitPassRepository(library: PassLibrarySpy(canAddToWatch: canAddToWatch))

        #expect(sut.canAddToRemoteDevice(primaryAccountIdentifier: "id-A") == canAddToWatch)
    }

    private func makeSUT(passes: [SecureElementPassDescribing]) -> PassKitPassRepository {
        PassKitPassRepository(library: PassLibrarySpy(passes: passes))
    }
}
