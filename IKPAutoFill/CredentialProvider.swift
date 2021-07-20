import AuthenticationServices
import CryptoSwift

class CredentialProvider {
    var identifier: ASCredentialServiceIdentifier?
    weak var extensionContext: ASCredentialProviderExtensionContext?

    init(extensionContext: ASCredentialProviderExtensionContext) {
        self.extensionContext = extensionContext
    }

    func credentials(for identity: ASPasswordCredentialIdentity) {
        guard let recordIdentifier = identity.recordIdentifier else { return }
        
       
        let adb = AutoFillDB()
        let dirNames = adb.GetSingleEntry(domain: recordIdentifier, userOnDomain: identity.user)
        
        if(dirNames == nil)
        {
            let error = NSError(domain: ASExtensionErrorDomain,
                                code: ASExtensionError.credentialIdentityNotFound.rawValue,
                                userInfo: nil)
            extensionContext?.cancelRequest(withError: error)
        }
        
        if(dirNames?.count == 0)
        {
            let error = NSError(domain: ASExtensionErrorDomain,
                                code: ASExtensionError.credentialIdentityNotFound.rawValue,
                                userInfo: nil)
            extensionContext?.cancelRequest(withError: error)
        }
        
        let domain = Directory(domain: recordIdentifier, username: identity.user, pwd: dirNames![0].pwd,hash:dirNames![0].hash,url: dirNames![0].url)
      
        //let username = Username(value: identity.user)
        guard let pwCredentials = provideCredentials(in: domain) else { return }

        extensionContext?.completeRequest(withSelectedCredential: pwCredentials)
    }

    func persistAndProvideCredentials(in domain: Directory) {
        guard let credentialIdentity = provideCredentialIdentity(for: identifier, in: domain) else { return }
        guard let pwCredentials = provideCredentials(in: domain) else { return }

        ASCredentialIdentityStore.shared.saveCredentialIdentities([credentialIdentity])
        extensionContext?.completeRequest(withSelectedCredential: pwCredentials)
    }
}

fileprivate func provideCredentialIdentity(for identifier: ASCredentialServiceIdentifier?,
                                           in domain: Directory) -> ASPasswordCredentialIdentity? {
    guard let serviceIdentifier = identifier else { return nil }

    return ASPasswordCredentialIdentity(serviceIdentifier: serviceIdentifier, user: domain.username, recordIdentifier: domain.domain)
}

fileprivate func provideCredentials(in domain: Directory) -> ASPasswordCredential? {
    //let password = "Test123" //decryptPassword(for: directory, with: username) else { return nil }
    guard let secure = domain.pwd.cryptoSwiftAESDecrypt(key: "RheinBrohl2021#!", iv:"o8!k3kp=)alk(2h/" ) else { return ASPasswordCredential(user: "unknown", password: "unknown") }
    
    return ASPasswordCredential(user: domain.username, password: secure)
}

extension String {
    func cryptoSwiftAESEncrypt(key: String, iv: String ) -> String? {
        let inputBytes: [UInt8] = Array(self.utf8)
            guard let dec = try? AES(key: key, iv: iv, padding: .pkcs7).encrypt(inputBytes) else {   return nil }
            let decData = Data(bytes: dec, count: Int(dec.count)).base64EncodedString(options: .lineLength64Characters)
            return decData
    }

    func cryptoSwiftAESDecrypt(key: String, iv: String) -> String? {
       
        let d = Data(base64Encoded: self)
        print("decodedData: \(d)")
        let encrypted: [UInt8] = Array(d!.bytes)


        guard let dec = try? AES(key: key, iv: iv, padding: .pkcs7).decrypt(encrypted) else {    return nil    }
        let decData = String(bytes: dec, encoding: .utf8)
            print("decryptedString: \(decData)")
        //let decData = Data(bytes: dec, count: Int(dec.count)) //.base64EncodedString(options: .lineLength64Characters)
        return decData
    }
}
