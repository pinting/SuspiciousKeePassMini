import LocalAuthentication


func verifyFace(_ then: @escaping () -> Void) {
    let reason = "Scan your face to decrypt your passwords..."
    LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: reason) { success, _ in
        if success {
            then()
        }
    }
}
