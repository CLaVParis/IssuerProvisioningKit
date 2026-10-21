# Integrating IssuerProvisioningKit

Add the framework to your Wallet extension and answer Wallet's status request.

## Overview

Wallet extensions let users add your cards from inside Wallet.
Wallet first calls `status(completion:)` on your non-UI extension to know whether to show your app at all.
IssuerProvisioningKit implements that call. The rest of the extension, such as `passEntries(completion:)`
and the sign-in UI, stays in your code.

### Check the requirements

- iOS 15.6 or later.
- The `com.apple.developer.payment-pass-provisioning` entitlement, requested from Apple,
  on the app and on both Wallet extensions.
- Your app ID and both extension IDs listed in `associatedApplicationIdentifiers`
  of your pass metadata. Your payment network or token service provider configures this.
  Without it, `PKPassLibrary` returns no pass and every card is reported as addable.

### Add the framework

Build the XCFramework from the repository root:

```bash
./scripts/build-xcframework.sh
```

Then add `build/IssuerProvisioningKit.xcframework` to your project:

1. In the **app** target, under **Frameworks, Libraries, and Embedded Content**, choose **Embed & Sign**.
2. In the **non-UI extension** target, add it with **Do Not Embed**.

The app ships one copy of the framework and the extension loads it from there.

### Answer the status request

Create the provider in your `PKIssuerProvisioningExtensionHandler` subclass and pass Wallet's
completion handler through:

```swift
import IssuerProvisioningKit
import PassKit

final class IssuerExtensionHandler: PKIssuerProvisioningExtensionHandler {
    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        let provider = IssuerProvisioningStatusProvider(
            lastDigits: CardStore.shared.lastDigits,
            requiresAuthentication: !CardStore.shared.hasValidSession
        )
        provider.status(completion: completion)
    }
}
```

`CardStore` stands for your own storage and is not part of the framework.

### Provide the last digits

Pass the last digits of every card the user could add, as printed on the card.
They are compared exactly with `primaryAccountNumberSuffix`, so:

- Keep them as strings to preserve leading zeros, for example `"0123"`.
- Use the same length as the suffix Wallet shows, usually four digits.
- Empty strings and duplicates are ignored.

> Important: Read them from local storage, such as an App Group or a shared keychain item
> written by your app. A network call would not fit in the 100 ms budget.

### Choose requiresAuthentication

Set it to `true` when Wallet must show your sign-in UI before listing cards,
for example when the user's session has expired. The framework never changes it.

### Share a pass library

The provider creates a `PKPassLibrary` by default. If your extension already holds one,
pass it in to avoid creating another:

```swift
IssuerProvisioningStatusProvider(
    lastDigits: lastDigits,
    requiresAuthentication: false,
    passLibrary: passLibrary
)
```

### Test on a device

The Simulator's Wallet holds no payment pass, so it always reports cards as addable.
Check the real behaviour on a device, with a build signed by a distribution profile,
since the payment pass provisioning entitlement does not work with development profiles.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Every card is reported as addable | `associatedApplicationIdentifiers` does not list the extension, or the entitlement is missing |
| A card in Wallet is reported as addable | Its last digits differ from `primaryAccountNumberSuffix`, for example a different length |
| Two cards with the same last digits, only one in Wallet, neither offered | Matching uses the last digits only, so both match the same pass |
| Wallet does not show your app | `status(completion:)` took more than 100 ms, or `passEntriesAvailable` and `remotePassEntriesAvailable` are both `false` |
