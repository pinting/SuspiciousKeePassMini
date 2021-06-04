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
                
                try cnn.execute("CREATE UNIQUE INDEX HASH_IDX ON AutoFill(HASH);")
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
        
    @objc public func AddEntry(user: String, secret: String, url: String){
        
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
                let sec = secret.cryptoSwiftAESEncrypt(key: "XXXXXXXXXXXXX", iv:"XXXXXXXXXXXXX" )
                let ha = String(format:"%@<->%@",user,url)
                let hash = ha.cryptoSwiftAESEncrypt(key: "XXXXXXXXXXXX", iv: "XXXXXXXXXXXXXXX")
                let ins = String(format:"INSERT INTO AutoFill (HASH,User,PWD,URL,DOMAIN) VALUES('%@','%@','%@','%@','%@');",hash!,user,sec!,url,domain)
                try cnn.execute(ins)
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
                    let hash = ha.cryptoSwiftAESEncrypt(key: "XXXXXXXXXXXXXX", iv: "XXXXXXXXXXXXX")
                    let del = String(format:"DELETE from AutoFill where HASH='%@';",hash!)
                    try cnn.execute(del)
                } catch {
                    print(error)
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
