//
//  Token.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2018 Matt Rubin and the OneTimePassword authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation



/// A `Token` contains a password generator and information identifying the corresponding account.
@objc public class Token: NSObject {//Equatable {
    /// A string indicating the account represented by the token.
    /// This is often an email address or username.
    @objc public let name: String

    /// A string indicating the provider or service which issued the token.
    @objc public let issuer: String
    
    /// A string indicating the secretfromurl or service which issued the token.
    @objc public let secretkey: String

    /// A password generator containing this token's secret, algorithm, etc.
    public let generator: Generator

    /// Initializes a new token with the given parameters.
    ///
    /// - parameter name:       The account name for the token (defaults to "").
    /// - parameter issuer:     The entity which issued the token (defaults to "").
    /// - parameter generator:  The password generator.
    ///
    /// - returns: A new token with the given parameters.
    public init(name: String = "", issuer: String = "", generator: Generator) {
        self.name = name
        self.issuer = issuer
        self.secretkey = "unkown"
        self.generator = generator
    }
    
    @objc public init(url: URL, secret: Data? = nil) throws {
        guard url.scheme == kOTPAuthScheme else {
            throw DeserializationError.invalidURLScheme
        }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        let factor: Generator.Factor
        switch url.host {
        case .some(kFactorCounterKey):
            let counterValue = try queryItems.value(for: kQueryCounterKey).map(parseCounterValue) ?? defaultCounter
            factor = .counter(counterValue)
        case .some(kFactorTimerKey):
            let period = try queryItems.value(for: kQueryPeriodKey).map(parseTimerPeriod) ?? defaultPeriod
            factor = .timer(period: period)
        case let .some(rawValue):
            throw DeserializationError.invalidFactor(rawValue)
        case .none:
            throw DeserializationError.missingFactor
        }

        let algorithm = try queryItems.value(for: kQueryAlgorithmKey).map(algorithmFromString) ?? defaultAlgorithm
        let digits = try queryItems.value(for: kQueryDigitsKey).map(parseDigits) ?? defaultDigits
        guard let secret = try secret ?? queryItems.value(for: kQuerySecretKey).map(parseSecret) else {
            throw DeserializationError.missingSecret
        }
        
        self.secretkey = try queryItems.value(for: kQuerySecretKey)!
        
        self.generator = try Generator(_factor: factor, secret: secret, algorithm: algorithm, digits: digits)

        // Skip the leading "/"
        let fullName = String(url.path.dropFirst())

        //let issuer: String
        if let issuerString = try queryItems.value(for: kQueryIssuerKey) {
            self.issuer = issuerString
        } else if let separatorRange = fullName.range(of: ":") {
            // If there is no issuer string, try to extract one from the name
            self.issuer = String(fullName[..<separatorRange.lowerBound])
        } else {
            // The default value is an empty string
            self.issuer = ""
        }

        // If the name is prefixed by the issuer string, trim the name
        self.name = shortName(byTrimming: issuer, from: fullName)
    }

    // Serializes the token to a URL.
    func toURL() throws -> URL {
        return try urlForToken(
            name: name,
            issuer: issuer,
            factor: generator.factor,
            algorithm: generator.algorithm,
            digits: generator.digits
        )
    }

    /// Attempts to initialize a token represented by the give URL.
   /* init?(url: URL, secret: Data? = nil) {
        try? self.init(_url: url, secret: secret)
    }

    // Eventually, this throwing initializer will replace the failable initializer above. For now, the failable
    // initializer remains to maintain a consistent public API. Since two different initializers cannot overload the
    // same initializer signature with both throwing an failable versions, this new initializer is currently prefixed
    // with an underscore and marked as internal.
    internal init(_url url: URL, secret: Data? = nil) throws {
        self = try token(from: url, secret: secret)
    }*/
    // MARK: Password Generation

    /// Calculates the current password based on the token's generator. The password generated will
    /// be consistent for a counter-based token, but for a timer-based token the password will
    /// depend on the current time when this property is accessed.
    ///
    /// - returns: The current password, or `nil` if a password could not be generated.
    @objc public var currentPassword: String? {
        let currentTime = Date()
        //print(currentTime)
        return try? generator.password(at: currentTime)
    }
    
    @objc public var currentPasswordmoreReadable: String? {
        let currentTime = Date()
        
        return try? generator.password(at: currentTime).prefix(3) + " " + generator.password(at: currentTime).suffix(3)
    }
    
  

    // MARK: Update

    /// - returns: A new `Token`, configured to generate the next password.
    @objc public func updatedToken() -> Token {
        return Token(name: name, issuer: issuer, generator: generator.successor())
    }
}


internal enum SerializationError: Swift.Error {
    case urlGenerationFailure
}

internal enum DeserializationError: Swift.Error {
    case invalidURLScheme
    case duplicateQueryItem(String)
    case missingFactor
    case invalidFactor(String)
    case invalidCounterValue(String)
    case invalidTimerPeriod(String)
    case missingSecret
    case invalidSecret(String)
    case invalidAlgorithm(String)
    case invalidDigits(String)
}

private let defaultAlgorithm: Generator.Algorithm = .sha1
private let defaultDigits: Int = 6
private let defaultCounter: UInt64 = 0
private let defaultPeriod: TimeInterval = 30

private let kOTPAuthScheme = "otpauth"
private let kQueryAlgorithmKey = "algorithm"
private let kQuerySecretKey = "secret"
private let kQueryCounterKey = "counter"
private let kQueryDigitsKey = "digits"
private let kQueryPeriodKey = "period"
private let kQueryIssuerKey = "issuer"

private let kFactorCounterKey = "hotp"
private let kFactorTimerKey = "totp"

private let kAlgorithmSHA1   = "SHA1"
private let kAlgorithmSHA256 = "SHA256"
private let kAlgorithmSHA512 = "SHA512"

private func stringForAlgorithm(_ algorithm: Generator.Algorithm) -> String {
    switch algorithm {
    case .sha1:
        return kAlgorithmSHA1
    case .sha256:
        return kAlgorithmSHA256
    case .sha512:
        return kAlgorithmSHA512
    }
}

private func algorithmFromString(_ string: String) throws -> Generator.Algorithm {
    switch string {
    case kAlgorithmSHA1:
        return .sha1
    case kAlgorithmSHA256:
        return .sha256
    case kAlgorithmSHA512:
        return .sha512
    default:
        throw DeserializationError.invalidAlgorithm(string)
    }
}

private func urlForToken(name: String, issuer: String, factor: Generator.Factor, algorithm: Generator.Algorithm, digits: Int) throws -> URL {
    var urlComponents = URLComponents()
    urlComponents.scheme = kOTPAuthScheme
    urlComponents.path = "/" + name

    var queryItems = [
        URLQueryItem(name: kQueryAlgorithmKey, value: stringForAlgorithm(algorithm)),
        URLQueryItem(name: kQueryDigitsKey, value: String(digits)),
        URLQueryItem(name: kQueryIssuerKey, value: issuer),
    ]

    switch factor {
    case .timer(let period):
        urlComponents.host = kFactorTimerKey
        queryItems.append(URLQueryItem(name: kQueryPeriodKey, value: String(Int(period))))
    case .counter(let counter):
        urlComponents.host = kFactorCounterKey
        queryItems.append(URLQueryItem(name: kQueryCounterKey, value: String(counter)))
    }

    urlComponents.queryItems = queryItems

    guard let url = urlComponents.url else {
        throw SerializationError.urlGenerationFailure
    }
    return url
}

private func token(from url: URL, secret externalSecret: Data? = nil) throws -> Token {
    guard url.scheme == kOTPAuthScheme else {
        throw DeserializationError.invalidURLScheme
    }

    let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

    let factor: Generator.Factor
    switch url.host {
    case .some(kFactorCounterKey):
        let counterValue = try queryItems.value(for: kQueryCounterKey).map(parseCounterValue) ?? defaultCounter
        factor = .counter(counterValue)
    case .some(kFactorTimerKey):
        let period = try queryItems.value(for: kQueryPeriodKey).map(parseTimerPeriod) ?? defaultPeriod
        factor = .timer(period: period)
    case let .some(rawValue):
        throw DeserializationError.invalidFactor(rawValue)
    case .none:
        throw DeserializationError.missingFactor
    }

    let algorithm = try queryItems.value(for: kQueryAlgorithmKey).map(algorithmFromString) ?? defaultAlgorithm
    let digits = try queryItems.value(for: kQueryDigitsKey).map(parseDigits) ?? defaultDigits
    guard let secret = try externalSecret ?? queryItems.value(for: kQuerySecretKey).map(parseSecret) else {
        throw DeserializationError.missingSecret
    }
    let generator = try Generator(_factor: factor, secret: secret, algorithm: algorithm, digits: digits)

    // Skip the leading "/"
    let fullName = String(url.path.dropFirst())

    let issuer: String
    if let issuerString = try queryItems.value(for: kQueryIssuerKey) {
        issuer = issuerString
    } else if let separatorRange = fullName.range(of: ":") {
        // If there is no issuer string, try to extract one from the name
        issuer = String(fullName[..<separatorRange.lowerBound])
    } else {
        // The default value is an empty string
        issuer = ""
    }

    // If the name is prefixed by the issuer string, trim the name
    let name = shortName(byTrimming: issuer, from: fullName)

    return Token(name: name, issuer: issuer, generator: generator)
}

private func parseCounterValue(_ rawValue: String) throws -> UInt64 {
    guard let counterValue = UInt64(rawValue) else {
        throw DeserializationError.invalidCounterValue(rawValue)
    }
    return counterValue
}

private func parseTimerPeriod(_ rawValue: String) throws -> TimeInterval {
    guard let period = TimeInterval(rawValue) else {
        throw DeserializationError.invalidTimerPeriod(rawValue)
    }
    return period
}

private func parseSecret(_ rawValue: String) throws -> Data {
    guard let secret = MF_Base32Codec.data(fromBase32String: rawValue) else {
        throw DeserializationError.invalidSecret(rawValue)
    }
    return secret
}

private func parseDigits(_ rawValue: String) throws -> Int {
    guard let digits = Int(rawValue) else {
        throw DeserializationError.invalidDigits(rawValue)
    }
    return digits
}

private func shortName(byTrimming issuer: String, from fullName: String) -> String {
    if !issuer.isEmpty {
        let prefix = issuer + ":"
        if fullName.hasPrefix(prefix), let prefixRange = fullName.range(of: prefix) {
            let substringAfterSeparator = fullName[prefixRange.upperBound...]
            return substringAfterSeparator.trimmingCharacters(in: Foundation.CharacterSet.whitespaces)
        }
    }
    return String(fullName)
}

extension Array where Element == URLQueryItem {
    func value(for name: String) throws -> String? {
        let matchingQueryItems = self.filter({
            $0.name == name
        })
        guard matchingQueryItems.count <= 1 else {
            throw DeserializationError.duplicateQueryItem(name)
        }
        return matchingQueryItems.first?.value
    }
}
