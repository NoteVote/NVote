//
//  SessionHandler.swift
//  
//  This class handles getting and storing the spotify session for persistence.
//  NSKeyedArchiver is used to encrypt data before it is stored in NSUserDefaults
//
//  Created by Aaron Kaplan on 9/29/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import Foundation

class SessionHandler {

    //private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    func storeSession(session:SPTSession) -> Bool {
        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
        userDefaults.setObject(sessionData, forKey: "session")
        userDefaults.synchronize()
        return true
    }
    
    func getSession() -> SPTSession? {
        let sessionData = userDefaults.objectForKey("session")
        
        if(sessionData == nil) {
            return nil
        }
        
        let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData as! NSData) as! SPTSession
        return session
    }
}