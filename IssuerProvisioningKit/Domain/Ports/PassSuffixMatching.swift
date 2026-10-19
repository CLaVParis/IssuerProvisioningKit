//
//  PassSuffixMatching.swift
//  IssuerProvisioningKit
//

/// Rule for comparing issuer `lastDigits` with a pass suffix.
///
/// Two values match when they produce the same key, so lookups can use a dictionary.
protocol PassSuffixMatching {
    func matchingKey(for digits: String) -> String
}
