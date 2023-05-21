import AuthenticationServices

class CredentialProviderViewController: ASCredentialProviderViewController {
    var embeddedNavigationController: UINavigationController {
        return children.first as! UINavigationController
    }

    var directoriesViewController: ViewPasswordDirectoriesViewController {
        return embeddedNavigationController.viewControllers.first as! ViewPasswordDirectoriesViewController
    }
    
     

    lazy var credentialProvider = CredentialProvider(extensionContext: self.extensionContext)

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        credentialProvider.identifier = serviceIdentifiers.first

        let url = serviceIdentifiers.first.flatMap { URL(string: $0.identifier) }
        directoriesViewController.showResultsMatching(url?.host?.sanitizedDomain)
    }

    override func viewDidLoad() {
        directoriesViewController.dataSource = DirectoriesTableViewDataSource(directories: fetchPasswordDirectories())
        directoriesViewController.navigator = self
       
    }

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        credentialProvider.credentials(for: credentialIdentity)
    }
}

extension CredentialProviderViewController: PasswordSelectionDelegate {
    func selectedPassword(for domain: Directory) {
        verifyFace { [weak self] in
            DispatchQueue.main.async {
                self?.credentialProvider.persistAndProvideCredentials(in: domain)
            }
        }
    }
}

extension CredentialProviderViewController: Navigator {
    func navigateToContentsOf(domain: Directory) {
        
        selectedPassword(for: domain)
        
    }

    private func cancelWith(_ errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain,
                            code: errorCode.rawValue,
                            userInfo: nil)

        self.extensionContext.cancelRequest(withError: error)
    }
    
    func navigateToPasswordsDirectory() { /* noop */ }
    func navigateToFetchRepository() {
        /* noop */
    }
    func navigateCancel() {
        /* noop */
        let error = NSError(domain: ASExtensionErrorDomain,
                            code: ASExtensionError.userCanceled.rawValue,
                            userInfo: nil)
        self.extensionContext.cancelRequest(withError: error)
     
    }
    
}

private extension String {
    var sanitizedDomain: String? {
        return replacingOccurrences(of: ".com", with: "")
            .replacingOccurrences(of: ".org", with: "")
            .replacingOccurrences(of: ".edu", with: "")
            .replacingOccurrences(of: ".net", with: "")
            .replacingOccurrences(of: ".gov", with: "")
            .replacingOccurrences(of: "www.", with: "")
    }
}

