//
//  AutoFillDB.swift
//  IOSKeePass
//
//  Created by Frank Hausmann on 16.05.21.
//  Copyright © 2021 Self. All rights reserved.
//

import Foundation
import CryptoSwift
import SQLite


@objc public class AutoFillDB: NSObject {
    let appGroupId = "group.de.unicomedv.KeePass"
    let fileManager = FileManager.default
    
    @objc public override init() {
       
        //var filepath = AppDelegate.documentsDirectoryUrl()
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        
        print("Using shared App Path: \(filepath!.path)")
            
        if !fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                
                try cnn.execute("CREATE TABLE IF NOT EXISTS AutoFill (id INTEGER PRIMARY KEY AUTOINCREMENT, HASH TEXT, User TEXT, PWD TEXT, URL TEXT, DOMAIN TEXT)")
                
                try cnn.execute("CREATE TABLE IF NOT EXISTS KeePassDBNames (id INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, LASTSYNC TEXT)")
                    
                //try cnn.execute("CREATE UNIQUE INDEX HASH_IDX ON AutoFill(HASH);")
                    
                } catch {
                    print(error)
                }
            }else{
                print("AutoFill DB available")
            }
        
    }
    
    
    @objc public func drop(){
       
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
            
            
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                try cnn.execute("DROP TABLE IF EXISTS AutoFill")
                } catch {
                    print(error)
                    
                }
            }
    }
    
    @objc public func RemoveDB(){
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
            
        if fileManager.fileExists(atPath: filepath!.path) {
            do{
                try fileManager.removeItem(atPath: filepath!.path)
            } catch {
                print(error)
            }
        }
    }
    @objc public func KeePassDBSync(dbname: String, syncdate: String){
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    let sel = String(format:"Select * from KeePassDBNames where NAME='%@'",dbname)
                    let rows = try cnn.prepare(sel)
                    var selection = 0
                    for row in rows{
                        selection=selection+1
                    }
                    if(selection == 0){
                        let ins = String(format:"INSERT INTO KeePassDBNames (NAME,LASTSYNC) VALUES('%@','%@');",dbname,syncdate)
                        try cnn.execute(ins)
                    }else{
                        
                        let ins = String(format:"UPDATE KeePassDBNames SET NAME='%@',LASTSYNC='%@'",dbname,syncdate)
                        try cnn.execute(ins)
                    }
                } catch {
                    print(error)
                }
            }
        
    }
    
    @objc public func IsKeePassInAutoFill(dbname: String)->Bool{
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    let sel = String(format:"Select * from KeePassDBNames where NAME='%@'",dbname)
                    let rows = try cnn.prepare(sel)
                    var selection = 0
                    for row in rows{
                        selection=selection+1
                    }
                    if(selection == 0){
                        return false
                    }else{
                        return true
                    }
                } catch {
                    print(error)
                }
            }
        return false
    }
    
    @objc public func InsertEntry(user: String, secret: String, url: String){
        
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        var domain = url
        if let url = URL(string: url)  {
            if let hostName = url.host  {
                 domain = hostName
            }
         }
        
            
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    let autofill = Table("AutoFill")
                    let hashfield = Expression<String>("HASH")
                    let dom = Expression<String>("DOMAIN")
                    let userfield = Expression<String>("User")
                    let pwd = Expression<String>("PWD")
                    let urlfield = Expression<String>("URL")
                    
                    let sec = secret.cryptoSwiftAESEncrypt(key: "xxxxxxx", iv:"xxxxxxx" )
                    let ha = String(format:"%@<->%@",user,url)
                    let hash = ha.cryptoSwiftAESEncrypt(key: "xxxxxxx#", iv: "xxxxx")
                    try cnn.run(autofill.insert(userfield <- user, pwd <- sec!, urlfield <- url, dom <- domain, hashfield <- hash!))
                    //let ins = String(format:"INSERT INTO AutoFill (HASH,User,PWD,URL,DOMAIN) VALUES('%@','%@','%@','%@','%@');",hash!,user,sec!,url,domain)xxx
                    //try cnn.execute(ins)
                    
                
                } catch {
                    print(error)
                }
            }
    }
    
    @objc public func AddOrUpdateEntry(user: String, secret: String, url: String){
        
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        var domain = url
        if let url = URL(string: url)  {
            if let hostName = url.host  {
                 domain = hostName
            }
         }
        
            
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    
                    let sec = secret.cryptoSwiftAESEncrypt(key: "xxxxxxx", iv:"xxxxxxx" )
                    let ha = String(format:"%@<->%@",user,url)
                    let hash = ha.cryptoSwiftAESEncrypt(key: "xxxxxxxx", iv: "xxxxxxxx")
                    let sel = String(format:"Select User,DOMAIN from AutoFill where User='%@' and DOMAIN='%@'",user,domain)
                    let rows = try cnn.prepare(sel)
                    var selection = 0
                    for row in rows{
                        selection=selection+1
                    }
                    
                    if(selection == 0){
                        let ins = String(format:"INSERT INTO AutoFill (HASH,User,PWD,URL,DOMAIN) VALUES('%@','%@','%@','%@','%@');",hash!,user,sec!,url,domain)
                        try cnn.execute(ins)
                    }else{
                        
                        let ins = String(format:"UPDATE AutoFill SET User='%@',PWD='%@',URL='%@' ",user,sec!,url)
                        try cnn.execute(ins)
                    }
                
                } catch {
                    print(error) 
                }
            }
    }
    
    @objc public func RemoveEntry(user: String,url: String){
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
            
            
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    let ha = String(format:"%@<->%@",user,url)
                    let hash = ha.cryptoSwiftAESEncrypt(key: "xxxxxxx", iv: "xxxxxx")
                    let del = String(format:"DELETE from AutoFill where HASH='%@';",hash!)
                    try cnn.execute(del)
                } catch {
                    print(error)x
                }
            }
    }
    
    func GetEntrys()
    {
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    let sel = String(format:"SELECT * from AutoFill;")
                    try cnn.execute(sel)
                } catch {
                    print(error)
                }
            }
    }
    
    

}

extension String {
    func cryptoSwiftAESEncrypt(key: String, iv: String ) -> String? {
            guard let dec = try? AES(key: key, iv: iv, padding: .pkcs7).encrypt(Array(self.utf8)) else {   return nil }
            let decData = Data(bytes: dec, count: Int(dec.count)).base64EncodedString(options: .lineLength64Characters)
            return decData
    }

    func cryptoSwiftAESDecrypt(key: String, iv: String) -> String? {
          guard let dec = try? AES(key: key, iv: iv, padding: .pkcs7).decrypt(Array(self.utf8)) else {    return nil    }
          let decData = Data(bytes: dec, count: Int(dec.count)).base64EncodedString(options: .lineLength64Characters)
          return decData
    }
}
