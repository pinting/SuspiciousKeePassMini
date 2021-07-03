//
//  AutoFillDB.swift
//  IOSKeePass
//
//  Created by Frank Hausmann on 16.05.21.
//  Copyright © 2021 Self. All rights reserved.
//

import Foundation
import SQLite

//This is the small Implemation only for Credetial Provider
public class AutoFillDB: NSObject {
    let appGroupId = "group.de.unicomedv.KeePass"
    let fileManager = FileManager.default
    
    public override init() {
       
        //var filepath = AppDelegate.documentsDirectoryUrl()
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        
        //print("Using shared App Path: \(filepath!.path)")
       
            
        if !fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                
                try cnn.execute("CREATE TABLE IF NOT EXISTS AutoFill (id INTEGER PRIMARY KEY AUTOINCREMENT, HASH TEXT, User TEXT, PWD TEXT, URL TEXT, DOMAIN TEXT)")
                
                //try cnn.execute("CREATE UNIQUE INDEX HASH_IDX ON AutoFill(HASH);")
                } catch {
                    print(error)
                }
            }else{
                print("AutoFill DB available")
            }
        
    }
    
    func GetSingleEntry(domain: String,userOnDomain: String) ->[Directory]?
    {
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    let autofill = Table("AutoFill")
                    let hash = Expression<String>("HASH")
                    let dom = Expression<String>("DOMAIN")
                    let user = Expression<String>("User")
                    let pwd = Expression<String>("PWD")
                    let url = Expression<String>("URL")
                    let query = autofill.filter(dom.like(domain) && user.like(userOnDomain))
                    let rows = try cnn.prepare(query)
                    // SELECT * FROM "users" WHERE ("verified" AND (lower("name") == 'alice'))
                    var dir = [Directory]()
                    for row in rows{
                        let dn = Directory(domain: row[dom], username: row[user], pwd: row[pwd], hash: row[hash], url: row[url])
                        dir.append(dn)
                    }
                return dir
            } catch {
                print(error)
            }
        }
    
    return nil
    }
    
    
    func GetDomEntrys() -> [Directory]?
    {
        var filepath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        filepath = filepath?.appendingPathComponent("AutoFill.db")
        
        if fileManager.fileExists(atPath: filepath!.path) {
                do{
                    let cnn = try Connection(filepath!.path)
                    let autofill = Table("AutoFill")
                    
                    let hash = Expression<String>("HASH")
                    let dom = Expression<String>("DOMAIN")
                    let user = Expression<String>("User")
                    let pwd = Expression<String>("PWD")
                    let url = Expression<String>("URL")
                    var dir = [Directory]()
                    let rows = try cnn.prepare(autofill)
                    
                    for row in rows{
                        let us = row[user]
                        if(!us.isEmpty){
                            let dn = Directory(domain: row[dom], username: us, pwd: row[pwd], hash: row[hash], url: row[url])
                            dir.append(dn)
                            print(dn)
                        }
                    }
                    return dir
                } catch {
                    print(error)
                }
            }
        
        return nil
    }
    
    

}


