# ``IssuerProvisioningKit``

Tells Wallet which of an issuer's cards can still be added to iPhone and Apple Watch.

## Overview

When the user taps the add button in Wallet, Wallet asks the issuer's extension for its status
through `status(completion:)` and ignores answers that take more than 100 ms.
IssuerProvisioningKit compares the last digits of the issuer's cards with the payment passes
already in Wallet and builds the `PKIssuerProvisioningExtensionStatus` for you.

```swift
import IssuerProvisioningKit
import PassKit

final class IssuerExtensionHandler: PKIssuerProvisioningExtensionHandler {
    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        IssuerProvisioningStatusProvider(lastDigits: ["1234", "5678"], requiresAuthentication: true)
            .status(completion: completion)
    }
}
```

The answer follows these rules:

- A card can be added to this device when no active pass in Wallet ends with its digits.
  A deactivated pass counts as absent.
- A card already on this device can be added to the paired Apple Watch when PassKit says so.
- `requiresAuthentication` is your choice and is passed through unchanged.

`completion` is called before `status(completion:)` returns, so the 100 ms budget is spent
only on reading Wallet.

## Topics

### Essentials

- <doc:IntegrationGuide>

### Reporting the Status

- ``IssuerProvisioningStatusProvider``
- ``IssuerProvisioningStatusProvider/init(lastDigits:requiresAuthentication:passLibrary:)``
- ``IssuerProvisioningStatusProvider/status(completion:)``
