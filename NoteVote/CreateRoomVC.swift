//
//  CreateRoomVC.swift
//  NVBeta
//
//  Created by Dustin Jones on 10/8/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import UIKit
import Parse

class CreateRoomVC: UIViewController, ENSideMenuDelegate {
    
    let sessionHandler = SessionHandler()
    var session:SPTSession? = nil
    @IBOutlet weak var roomName: UITextField!
    
    // MARK: - ENSideMenu Delegate
    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
    }
    
    func sideMenuWillClose() {
        print("sideMenuWillClose")
    }
    
    func sideMenuShouldOpenSideMenu() -> Bool {
        print("sideMenuShouldOpenSideMenu")
        return false
    }
    
    func sideMenuDidClose() {
        print("sideMenuDidClose")
    }
    
    func sideMenuDidOpen() {
        print("sideMenuDidOpen")
    }

    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("CreateRoom_Home", sender: nil)
    }
    
    //TODO: Still need to add slide button for private Switch.
    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        print(roomName.text!)
        serverLink.musicList = []
        serverLink.songsVoted[session!.canonicalUsername] = []
        serverLink.addParty(roomName.text!, partyID: session!.canonicalUsername, priv: false)
        userDefaults.setObject(roomName.text!, forKey: "currentRoom")
        userDefaults.setObject(session!.canonicalUsername, forKey: "roomID")
        userDefaults.synchronize()
        self.performSegueWithIdentifier("CreateRoom_HostRoom", sender: nil)
        
    }
    
    func setCurrentSession(session: SPTSession) {
        self.session = session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self;
        let sessionHandler = SessionHandler()
        let session = sessionHandler.getSession()
        setCurrentSession(session!)
    }

    
    
}
