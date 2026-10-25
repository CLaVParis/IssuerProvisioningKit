# IssuerProvisioningKit

![iOS 15.6+](https://img.shields.io/badge/iOS-15.6%2B-blue)
![Swift 5](https://img.shields.io/badge/Swift-5-orange)
![Tests 67](https://img.shields.io/badge/tests-67-brightgreen)
![Coverage 99%](https://img.shields.io/badge/coverage-99%25-brightgreen)

An iOS framework that answers Wallet's `status(completion:)` call for a card issuer's Wallet extension.
It has no third-party dependency.

## Contents

1. [Overview](#overview)
2. [How the Brief Is Met](#how-the-brief-is-met)
3. [Decisions Beyond the Brief](#decisions-beyond-the-brief)
4. [Usage](#usage)
5. [Compatibility](#compatibility)
6. [Design](#design)
7. [Performance](#performance)
8. [Testing](#testing)
9. [Open Discussion](#open-discussion)
10. [Extending](#extending)

## Overview

Before listing an issuer in its "add card" screen, Wallet asks the issuer's extension whether there is anything to add.
This framework gives that answer: one answer for the iPhone and one for the Watch, not one per card.

### Input

The issuer's cards, and the passes already in Wallet:

```swift
lastDigits: ["1111", "2222", "3333"]
requiresAuthentication: false
```

| Pass in Wallet | State       | Watch can add it |
| -------------- | ----------- | ---------------- |
| `1111`         | Active      | Yes              |
| `2222`         | Deactivated |                  |

### Output

The `PKIssuerProvisioningExtensionStatus` given to Wallet's completion handler:

```swift
passEntriesAvailable: true         // 2222 and 3333 can be added to the iPhone
remotePassEntriesAvailable: true   // 1111 can be added to the Watch
requiresAuthentication: false      // copied from the issuer
```

| Property                     | Meaning                                                |
| ---------------------------- | ------------------------------------------------------ |
| `passEntriesAvailable`       | `true` if at least one card can be added to the iPhone |
| `remotePassEntriesAvailable` | `true` if at least one card can be added to the Watch  |
| `requiresAuthentication`     | Copied from the issuer                                 |

Wallet uses it to decide whether to show the issuer, and for which device.
The list of cards comes later, from `passEntries` and `remotePassEntries`, which are out of scope.

**Other features are easy to add on top of this project (for example, returning the status of each card).**

### Logic

Each value of `lastDigits` is compared with the `primaryAccountNumberSuffix` of the passes
returned by `PKPassLibrary.passes(of: .secureElement)`:

1. No pass matches, or only a deactivated one: the card can be added to the iPhone.
2. A pass in any other state matches: the card is already on the iPhone.
   `canAddSecureElementPass(primaryAccountIdentifier:)` then tells whether it can be added to the Watch.

Applied to the input above, then combined per device:

| Card       | Match            | Addable to iPhone | Addable to Watch |
| ---------- | ---------------- | ----------------- | ---------------- |
| `1111`     | Active pass      | No                | Yes              |
| `2222`     | Deactivated pass | Yes               | No               |
| `3333`     | None             | Yes               | No               |
| **Status** |                  | **`true`**        | **`true`**       |

### Highlights

- Every rule of the brief has its code and its test.
- Cases the brief leaves open are decided and tested.
- The decision logic imports nothing and is tested without PassKit.
- Wallet is read once and matched in O(n + m), far below 100 ms.
- 67 tests, 99% line coverage.

## How the Brief Is Met

Every rule of the brief, where it is implemented, and the test that checks it.

### Logic

| Brief                                        | Code                                       | Test                                    |
| -------------------------------------------- | ------------------------------------------ | --------------------------------------- |
| Logic for `status(completion:)` only         | `IssuerProvisioningStatusProvider`         | `PublicAPITests`                        |
| Input is a list of `lastDigits`              | `init(lastDigits:requiresAuthentication:)` | `forwardsIssuerInputToEvaluator`        |
| Read `passes(of: .secureElement)`            | `PassLibrary.swift`                        | `PassKitPassRepositoryTests`            |
| Match with `primaryAccountNumberSuffix`      | `ProvisioningStatusEvaluator`              | `availability`                          |
| No match: card can be added                  | `passEntriesAvailable = true`              | `availability`                          |
| Not `deactivated`: card is present           | `PassKitPassRepository`                    | `passStateDecidesIfCardCanBeAdded`      |
| Watch check with `primaryAccountIdentifier`  | `canAddToRemoteDevice`                     | `watchCheckUsesIdentifierOfMatchedPass` |
| iPhone and Watch declared separately         | Two independent flags                      | `availability`                          |
| `requiresAuthentication` set by the customer | Passed through                             | `requiresAuthenticationIsPassedThrough` |

### Tests

| Brief                                     | Where                                              |
| ----------------------------------------- | -------------------------------------------------- |
| Cover multiple scenarios                  | 18 scenarios in `ProvisioningStatusEvaluatorTests` |
| Simulate passes and `PKPassLibrary`       | `TestDoubles/`                                     |
| Verify the 100 ms limit                   | `IssuerProvisioningStatusPerformanceTests`         |
| Name a variable after your favorite color | `violet`, see below                                |

### Favorite color

`violet` is the pass being matched. The test checks that the Watch is asked about this pass, by its identifier:

```swift
let violet = SecureElementPassRecord.fixture(id: "id-violet", suffix: "4242")
let (sut, _, watchChecker) = makeSUT(
    passes: [violet, .fixture(id: "id-other", suffix: "1111")],
    watchEligibleIdentifiers: []
)

_ = sut.evaluate(lastDigits: [violet.primaryAccountNumberSuffix], requiresAuthentication: false)

#expect(watchChecker.requestedIdentifiers == [violet.primaryAccountIdentifier])
```

### Delivery

#### The framework

Open `IssuerProvisioningKit.xcodeproj` and choose **Product > Build**.
**Product > Show Build Folder in Finder** opens `IssuerProvisioningKit.framework`,
under `Products/Debug-iphoneos/` or `Products/Debug-iphonesimulator/`.

#### The XCFramework

I also wrote a script that packages the framework as an XCFramework, the format Apple recommends for shipping binaries.
Run it from the repository root:

```bash
./scripts/build-xcframework.sh
```

## Decisions Beyond the Brief

Cases the brief does not cover, and what the framework does.

| Case                                            | Decision                                  |
| ----------------------------------------------- | ----------------------------------------- |
| Empty `lastDigits` entry                        | Ignored                                   |
| Same `lastDigits` twice                         | Checked once                              |
| Spaces, leading zeros                           | Exact match, nothing trimmed              |
| Several active passes with one suffix           | Watch: `true` if any of them can be added |
| `requiresActivation`, `activating`, `suspended` | Present on the iPhone                     |
| Empty `lastDigits` list                         | Both flags `false`, Wallet not read       |
| Card not on the iPhone                          | Watch not asked                           |
| Watch already `true`                            | Not asked again                           |
| Completion                                      | Called before `status` returns            |
| Cache                                           | None                                      |
| `requiresAuthentication` default                | None                                      |

<details>
<summary>Reasons and tests</summary>

- **Empty entry.** `""` matches no pass, so it would look like an addable card.
  Test: "Empty lastDigits entry" scenarios.
- **Duplicates.** Each Watch check is a PassKit call. Asking twice gives the same answer.
  Test: `duplicateLastDigitsAreCheckedOnce`.
- **Exact match.** Trimming would hide bad issuer data. `"0123"` is a string, so the zero stays.
  Test: "Suffix must match exactly", "Leading zero is kept".
- **Shared suffix.** A reissued card often keeps its last digits.
  Test: "Several active passes share a suffix".
- **Other states.** The brief only treats `deactivated` as absent. Adding a suspended card again would duplicate it.
  Test: `passStateDecidesIfCardCanBeAdded`.
- **Empty list.** Nothing to compare, so the call to Wallet is skipped.
  Test: `walletIsNotReadWithoutLastDigits`.
- **Card not on the iPhone.** `canAddSecureElementPass` needs the identifier of an existing pass.
  Test: `watchIsNotAskedAboutCardsAbsentFromDevice`. See [Open Discussion](#open-discussion).
- **Watch already `true`.** The status is per device, so one card is enough.
  Test: `watchIsNotAskedAgainOnceAnswerIsKnown`.
- **Synchronous completion.** A dispatch would only add delay inside the 100 ms.
  Test: `callsCompletionBeforeReturning`.
- **No cache.** Cards can change between two calls, and the extension lives briefly.
  Test: `walletIsReadAgainOnEveryCall`.
- **No default.** A wrong default would skip or force sign-in. The issuer must choose, and the compiler enforces it.

</details>

## Usage

Call the provider from the issuer's Wallet extension:

```swift
import IssuerProvisioningKit
import PassKit

final class IssuerExtensionHandler: PKIssuerProvisioningExtensionHandler {
    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        IssuerProvisioningStatusProvider(
            lastDigits: CardStore.shared.lastDigits,
            requiresAuthentication: !CardStore.shared.hasValidSession
        )
        .status(completion: completion)
    }
}
```

- `CardStore` is the issuer's local storage, such as an App Group. A network call would not fit in 100 ms.
- An existing `PKPassLibrary` can be passed with `passLibrary:`.
- The full guide is in [`IntegrationGuide.md`](IssuerProvisioningKit/IssuerProvisioningKit.docc/IntegrationGuide.md).

## Compatibility

- iOS 15.6 or later.
- Xcode 16.2, Swift 5.
- The `com.apple.developer.payment-pass-provisioning` entitlement on the app and both extensions.
- The app and extension IDs in `associatedApplicationIdentifiers` of the pass metadata.

## Design

The code follows Clean Architecture. Dependencies point inward, toward the Domain.

| Layer             | Contents                           | Imports |
| ----------------- | ---------------------------------- | ------- |
| `Domain/`         | Entities, ports, evaluator         | Nothing |
| `Infrastructure/` | PassKit adapters                   | PassKit |
| `Public/`         | `IssuerProvisioningStatusProvider` | PassKit |

The diagrams are in [`ARCHITECTURE.html`](ARCHITECTURE.html). GitHub shows its source, so download it and open it in a browser.

<details>
<summary>Clean Architecture and SOLID in the code</summary>

### Composition root

The public initializer is the only place that creates concrete types:

```swift
public convenience init(lastDigits: [String],
                        requiresAuthentication: Bool,
                        passLibrary: PKPassLibrary = PKPassLibrary()) {
    let repository = PassKitPassRepository(library: passLibrary)
    self.init(
        lastDigits: lastDigits,
        requiresAuthentication: requiresAuthentication,
        evaluator: ProvisioningStatusEvaluator(passProvider: repository, remoteEligibilityChecker: repository)
    )
}
```

### Single responsibility

The mapper only copies fields into PassKit's type:

```swift
struct PassKitStatusMapper {
    func status(from availability: ProvisioningAvailability) -> PKIssuerProvisioningExtensionStatus {
        let status = PKIssuerProvisioningExtensionStatus()
        status.passEntriesAvailable = availability.passEntriesAvailable
        status.remotePassEntriesAvailable = availability.remotePassEntriesAvailable
        status.requiresAuthentication = availability.requiresAuthentication
        return status
    }
}
```

### Open/closed

The evaluator depends on protocols. A new pass source needs no change to it:

```swift
struct ProvisioningStatusEvaluator: ProvisioningStatusEvaluating {
    private let passProvider: SecureElementPassProviding
    private let remoteEligibilityChecker: RemotePassEligibilityChecking
}
```

### Liskov substitution

`PKPassLibrary` and the test spy both conform to `PassLibrary`, and the repository uses either one the same way:

```swift
extension PKPassLibrary: PassLibrary {
    func secureElementPasses() -> [SecureElementPassDescribing] {
        passes(of: .secureElement).compactMap(\.secureElementPass)
    }
}
```

### Interface segregation

Two ports with one method each, instead of one wide protocol:

```swift
protocol SecureElementPassProviding {
    func secureElementPasses() -> [SecureElementPassRecord]
}

protocol RemotePassEligibilityChecking {
    func canAddToRemoteDevice(primaryAccountIdentifier: String) -> Bool
}
```

### Dependency inversion

The Domain owns the ports. Infrastructure implements them:

```swift
final class PassKitPassRepository: SecureElementPassProviding, RemotePassEligibilityChecking {
    private let library: PassLibrary
}
```

</details>

## Performance

Wallet ignores an answer that takes more than 100 ms. Most of the time goes into PassKit's calls to Wallet,
so the framework makes as few of them as it can.

<details>
<summary>Details</summary>

- Wallet is read once per call, then indexed by suffix. Matching is O(n + m) instead of O(n × m).
- The Watch is asked only about cards on the iPhone, once per card, and not after the first `true`.
- The loop stops as soon as both flags are `true`.
- An empty `lastDigits` list returns before reading Wallet.
- The completion is called directly, with no dispatch.
- No cache: it would save little in a short-lived extension and could return a stale answer.
- Entities are small structs. Four-digit strings are stored inline, with no heap allocation.

The worst case, 10,000 passes and 10,000 digits with no early exit, is tested against the 100 ms limit.

</details>

## Testing

Run the 67 tests on a simulator:

```bash
xcodebuild test \
  -project IssuerProvisioningKit.xcodeproj \
  -scheme IssuerProvisioningKit \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

| Suite                                      | Cases | Covers                          |
| ------------------------------------------ | ----- | ------------------------------- |
| `ProvisioningStatusEvaluatorTests`         | 29    | The rule, 18 scenarios          |
| `PassKitPassRepositoryTests`               | 11    | PassKit pass to domain record   |
| `PassKitStatusMapperTests`                 | 8     | Domain result to PassKit status |
| `IssuerProvisioningStatusProviderTests`    | 12    | Completion, end to end          |
| `PublicAPITests`                           | 3     | The API as an issuer sees it    |
| `IssuerProvisioningStatusPerformanceTests` | 4     | The 100 ms limit                |

<details>
<summary>Details</summary>

### Two test frameworks

- Swift Testing for the logic: parameterized scenarios, and `confirmation` to count completion calls.
- XCTest for performance: `XCTWaiter` reports a timeout as a result, and `measure` exists only in XCTest.

### The 100 ms check

`status` calls its completion synchronously, so waiting after the call would always pass.
The test calls `status` on a background queue and waits for the completion.
`test_waitForCompletion_reportsTimeout_whenStatusIsSlow` uses a 200 ms stub to prove the check can fail.

### Test doubles

- `PassLibrarySpy` replaces `PKPassLibrary`.
- `SecureElementPassStub` replaces `PKSecureElementPass`, which cannot be created with a chosen state.
- The provider and checker spies record what PassKit is asked.

### Coverage

121 of 122 lines. The missing one is the `\.secureElementPass` key path in `PassLibrary.swift`,
which only runs when Wallet holds a payment pass. The Simulator's Wallet is always empty.

### No `measure` baseline

Baselines are tied to one Mac. The 100 ms assertions are the real check.

</details>

## Open Discussion

Limits of the brief's rule, and how they were handled.

### Two cards with the same last digits

Matching on the suffix cannot tell them apart. If one is in Wallet, both match it, and the other is not offered.
The brief defines this rule, so it is kept and tested.
Matching by account identifier would fix it, see [Extending](#extending).

### A card not on the iPhone is never checked for the Watch

`canAddSecureElementPass` needs the identifier of an existing pass, and a missing card has none.
A card the user wants only on the Watch is therefore not counted.
Fixing it needs account identifiers from the issuer, or `remoteSecureElementPasses`.

### A wrong setup looks like an empty Wallet

Without the entitlement or the pass metadata, `passes(of:)` returns nothing, so every card looks addable.
PassKit cannot tell this apart from an empty Wallet, so the symptom is described in the integration guide.

<details>
<summary>Other points</summary>

- **Other states.** Only `deactivated` counts as absent, as in the brief. `suspended` could be argued either way.
- **Slow PassKit.** The framework cannot make Wallet faster. It only keeps the number of calls low.
- **Digit format.** Length and leading zeros are up to the issuer.
- **Abstraction.** Three protocols around one PassKit class is more than strictly needed, but it makes the rule testable.
- **Real device.** Real passes can only be checked on a device, with a distribution build.
- **Other handler functions.** `passEntries`, `remotePassEntries` and `generateAddPaymentPassRequest` are out of scope.

</details>

## Extending

Possible next steps, building on the current structure:

| Direction             | Idea                                              |
| --------------------- | ------------------------------------------------- |
| Status of each card   | Return a result per card, next to the summary     |
| Card list for Wallet  | Implement `passEntries` on the same Wallet access |
| More precise matching | Match cards on more than the last digits          |
| Diagnostics           | Optional logging, without card data               |
| Easier integration    | Swift Package Manager, Objective-C support        |

### OWASP Mobile Top 10

The current scope was checked against the OWASP Mobile Top 10 (2024). Most risks do not apply yet,
so no protection was added for them. They are listed here because new features can bring them in.

<details>
<summary>Risk by risk</summary>

| Risk                 | Today                                    | When extending                           |
| -------------------- | ---------------------------------------- | ---------------------------------------- |
| M1 Credentials       | None handled                             | Only if sign-in moves into the framework |
| M2 Supply Chain      | No third-party dependency                | Sign each release                        |
| M3 Authentication    | Decided by the issuer                    | Keep it with the issuer                  |
| M4 Input Validation  | Empty and duplicate digits ignored       | Check every new input                    |
| M5 Communication     | No network                               | Secure connections only                  |
| M6 Privacy           | Never reads the full card number         | Never log card data                      |
| M7 Binary Protection | No secret in the binary                  | Only needed if secrets are added         |
| M8 Misconfiguration  | Setup documented                         | Document every new requirement           |
| M9 Data Storage      | Nothing stored                           | Keychain, if a cache is added            |
| M10 Cryptography     | Nothing encrypted                        | System cryptography only                 |

</details>
