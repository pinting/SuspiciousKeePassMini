struct Username {
    let value: String

    var withoutFileExtension: String {
        return String(value.dropLast(4))
    }
}
