import Foundation


let sharedDocumentsDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.de.unicomedv.KeePass")!
let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

func listDocumentSubdirectories(for paths: [String]) throws -> [Directory] {
    //let url = paths.reduce(sharedDocumentsDirectory) { $0.appendingPathComponent($1) }
    //var dirNames = try FileManager.default.contentsOfDirectory(atPath: url.path)
    
    let adb = AutoFillDB()
    let dirNames = adb.GetDomEntrys()
   
    
    return dirNames! //dirNames.map { Directory(name: $0) }
}

func getUsernamesFor(directory: Directory) -> [Username] {
    do {
        let subdirs = try listDocumentSubdirectories(for: ["AutoFill.db", directory.domain])
        return subdirs.map { Username(value: $0.domain) }
    } catch {
        return []
    }
}

func fetchPasswordDirectories() -> [Directory] {
    do {
        return try listDocumentSubdirectories(for: ["AutoFill.db"])
    } catch {
        return []
    }
}
