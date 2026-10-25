# IssuerProvisioningKit – Architecture

IssuerProvisioningKit answers one question for an issuer's Wallet extension:
can at least one of the issuer's cards still be added to this iPhone, and to the paired Apple Watch.

This document follows the [4+1 view model](https://en.wikipedia.org/wiki/4%2B1_architectural_view_model):
the logical, process, development and physical views, tied together by scenarios.

1. [Logical View](#1-logical-view)
2. [Process View](#2-process-view)
3. [Development View](#3-development-view)
4. [Physical View](#4-physical-view)
5. [Scenarios (+1)](#5-scenarios-1)

## 1. Logical View

The framework is split into three layers. Dependencies only point inwards, towards the Domain.

```text
┌─ Public ─────────────────────────────────────────────────────────┐
│                 IssuerProvisioningStatusProvider                 │
└──────────────────────────────────────────────────────────────────┘
        │ depends on ProvisioningStatusEvaluating and PassKitStatusMapper
        ▼
┌─ Domain ─────────────────────────────────────────────────────────┐
│                  «ProvisioningStatusEvaluating»                  │
│                                 ▲ implemented by                 │
│                                 │                                │
│                   ProvisioningStatusEvaluator                    │
│                                 │ depends on                     │
│                                 ▼                                │
│  «SecureElementPassProviding»   «RemotePassEligibilityChecking»  │
│                                                                  │
│    Values: SecureElementPassRecord, ProvisioningAvailability     │
└──────────────────────────────────────────────────────────────────┘
        ▲ both Domain ports implemented by PassKitPassRepository
        │
┌─ Infrastructure ─────────────────────────────────────────────────┐
│    PassKitPassRepository          PassKitStatusMapper            │
│              │ depends on                                        │
│              ▼                                                   │
│    «PassLibrary» ── returns ──▶ «SecureElementPassDescribing»    │
└──────────────────────────────────────────────────────────────────┘
        ▲ adopted by
        │
┌─ PassKit (Apple) ────────────────────────────────────────────────┐
│    PKPassLibrary                  PKSecureElementPass            │
└──────────────────────────────────────────────────────────────────┘
```

`«Name»` is a protocol. Other names are concrete types.

### Domain

Pure Swift, no `import PassKit`. Holds the rule from the brief and can be tested without Wallet.

| Type                            | Kind     | Role                                                                         |
| ------------------------------- | -------- | ---------------------------------------------------------------------------- |
| `SecureElementPassRecord`       | Entity   | A pass already in Wallet: identifier, suffix, and whether it is deactivated  |
| `ProvisioningAvailability`      | Entity   | The answer: available on device, available on Watch, requires authentication |
| `SecureElementPassProviding`    | Port     | Where passes come from                                                       |
| `RemotePassEligibilityChecking` | Port     | Whether a pass can still go to the Watch                                     |
| `ProvisioningStatusEvaluating`  | Port     | The use case seen from the Public layer                                      |
| `ProvisioningStatusEvaluator`   | Use case | Compares `lastDigits` with the passes in Wallet                              |

### Infrastructure

Adapters between the Domain and PassKit. The only layer that knows about Apple types.

| Type                          | Role                                                                                             |
| ----------------------------- | ------------------------------------------------------------------------------------------------ |
| `PassKitPassRepository`       | Implements both Domain ports on top of `PassLibrary`                                             |
| `PassKitStatusMapper`         | Turns `ProvisioningAvailability` into `PKIssuerProvisioningExtensionStatus`                      |
| `PassLibrary`                 | The two `PKPassLibrary` calls the framework makes, adopted by `PKPassLibrary`                    |
| `SecureElementPassDescribing` | The three `PKSecureElementPass` properties the framework reads, adopted by `PKSecureElementPass` |

### Public

| Type                               | Role                                                                                                                    |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `IssuerProvisioningStatusProvider` | The only public type. Composition root: wires the PassKit adapters into the evaluator and exposes `status(completion:)` |

The public surface is one convenience initializer and one method.
Everything else is `internal`, so it can change without breaking issuers.

## 2. Process View

One call from Wallet, step by step.

| Step | Who                              | What                                                                                                        |
| ---- | -------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 1    | Wallet → extension               | `status(completion:)`                                                                                       |
| 2    | extension → Provider             | `status(completion:)`                                                                                       |
| 3    | Provider → Evaluator             | `evaluate(lastDigits:requiresAuthentication:)`                                                              |
| 4    | Evaluator                        | Drop empty and duplicate `lastDigits`. Return early if none are left                                        |
| 5    | Evaluator → Repository → PassKit | `PKPassLibrary.passes(of: .secureElement)`, converted to `SecureElementPassRecord`                          |
| 6    | Evaluator                        | Index active passes by suffix. Deactivated passes are dropped                                               |
| 7    | Evaluator                        | For each `lastDigits` entry, until both answers are `true`:                                                 |
| 7a   | Evaluator                        | Suffix not found: `passEntriesAvailable = true`                                                             |
| 7b   | Evaluator → Repository → PassKit | Suffix found: `canAddSecureElementPass(primaryAccountIdentifier:)`, skipped once the Watch answer is `true` |
| 8    | Evaluator → Provider             | `ProvisioningAvailability`, mapped by `PassKitStatusMapper`                                                 |
| 9    | Provider → Wallet                | `completion(PKIssuerProvisioningExtensionStatus)`, before `status` returns                                  |

## 3. Development View

### Source layout

```text
IssuerProvisioningKit/
├── Domain/
│   ├── Entities/          SecureElementPassRecord, ProvisioningAvailability
│   ├── Ports/             SecureElementPassProviding, RemotePassEligibilityChecking,
│   │                      ProvisioningStatusEvaluating
│   └── UseCases/          ProvisioningStatusEvaluator
├── Infrastructure/        PassKitPassRepository, PassKitStatusMapper,
│                          PassLibrary, SecureElementPassDescribing
└── Public/                IssuerProvisioningStatusProvider

IssuerProvisioningKitTests/
├── Domain/                ProvisioningStatusEvaluatorTests
├── Infrastructure/        PassKitPassRepositoryTests, PassKitStatusMapperTests
├── Public/                IssuerProvisioningStatusProviderTests, PublicAPITests,
│                          IssuerProvisioningStatusPerformanceTests
└── TestDoubles/           Spies, stubs and fixtures

scripts/
└── build-xcframework.sh
```

The test folders mirror the source folders, so the test for a type is always in the same place.

### Tests

| Framework     | Used for        | Why                                             |
| ------------- | --------------- | ----------------------------------------------- |
| Swift Testing | Logic: 63 cases | Parameterized tests keep each scenario readable |
| XCTest        | Timing: 4 cases | Checks the 100 ms limit                         |

| Suite                                      | Cases | What it covers                                                                                                |
| ------------------------------------------ | ----- | ------------------------------------------------------------------------------------------------------------- |
| `ProvisioningStatusEvaluatorTests`         | 29    | The rule from the brief, 18 scenarios, plus how often PassKit is asked                                        |
| `PassKitPassRepositoryTests`               | 11    | Every `passActivationState`, field copying, the Watch call                                                    |
| `PassKitStatusMapperTests`                 | 8     | All 8 combinations of the three flags                                                                         |
| `IssuerProvisioningStatusProviderTests`    | 12    | Completion called once and synchronously, every pass state end to end, real `PKPassLibrary`, concurrent calls |
| `PublicAPITests`                           | 3     | The framework used as an issuer would, without `@testable`                                                    |
| `IssuerProvisioningStatusPerformanceTests` | 4     | 100 ms with 20 passes and with 10,000 passes; a slow stub proves the check can fail                           |

Line coverage of the framework is 99.2%.
The only line not covered is the `\.secureElementPass` key path in `PassLibrary.swift`,
which runs only when the real Wallet holds a card, so only on a device.

### Build

The shared scheme `IssuerProvisioningKit` runs the tests with coverage limited to the framework target.
`scripts/build-xcframework.sh` produces the binary for distribution. Build products are never committed.

## 4. Physical View

### Distribution

```text
┌─ IssuerProvisioningKit.xcframework ──────────────────────────────────────┐
│ ios-arm64                      iPhone and iPad                           │
│ ios-arm64_x86_64-simulator     Simulator, Apple silicon and Intel Macs   │
└──────────────────────────────────────────────────────────────────────────┘
```

### Runtime

```text
┌─ iPhone ─────────────────────────────────────────────────────────┐
│                            Wallet app                            │
│                                 │ status(completion:)            │
│                                 ▼                                │
│   ┌─ Issuer app ─────────────────────────────────────────────┐   │
│   │ ┌─ Issuer Provisioning extension ──────────────────────┐ │   │
│   │ │           IssuerProvisioningKit.framework            │ │   │
│   │ └──────────────────────────────────────────────────────┘ │   │
│   └──────────────────────────────────────────────────────────┘   │
│                                 │ PassKit                        │
│                                 ▼                                │
│                      System Wallet service                       │
└──────────────────────────────────────────────────────────────────┘
                                  ▲
                                  │ paired device
                                  ▼
                            Apple Watch
```

## 5. Scenarios (+1)

Each scenario shows how the views above work together. `lastDigits` is what the issuer passes in.

| #   | Wallet                                    | `lastDigits`               | Device  | Watch               | Path through the code                                              |
| --- | ----------------------------------------- | -------------------------- | ------- | ------------------- | ------------------------------------------------------------------ |
| 1   | Empty                                     | `["1234"]`                 | `true`  | `false`             | Suffix not found, Watch never asked                                |
| 2   | `1234`, active                            | `["1234"]`                 | `false` | `true`              | Suffix found, `canAddSecureElementPass` returns `true`             |
| 3   | `1234`, active, already on Watch          | `["1234"]`                 | `false` | `false`             | Suffix found, `canAddSecureElementPass` returns `false`            |
| 4   | `1234`, deactivated                       | `["1234"]`                 | `true`  | `false`             | Pass dropped before indexing, so the card counts as absent         |
| 5   | `1234` old deactivated, `1234` new active | `["1234"]`                 | `false` | Depends on new pass | Only the active pass is indexed and sent to the Watch check        |
| 6   | `1111` active, addable to Watch           | `["9999", "1111", "2222"]` | `true`  | `true`              | Both answers are `true` after `1111`, so `2222` is never looked at |
| 7   | Anything                                  | `[]` or `[""]`             | `false` | `false`             | Returns before reading Wallet                                      |

`requiresAuthentication` is never computed. The issuer sets it and it is passed through unchanged.
