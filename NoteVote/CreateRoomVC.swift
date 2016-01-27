//
//  CreateRoomVC.swift
//  NVBeta
//
//  Created by Dustin Jones on 10/8/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import UIKit
import Parse

class CreateRoomVC: UIViewController, ENSideMenuDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let sessionHandler = SessionHandler()
    var session:SPTSession? = nil
    @IBOutlet weak var roomName: UITextField!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    var privateParty:Bool = false
    let playlistNames:[String] = ["good times","Party Harty", "My Jams!"]
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

    @IBAction func privateSwitchSwitched(sender: UISwitch) {
        self.privateParty = !self.privateParty
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
    
//------------Picker View Methods-----------------
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.playlistNames.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.playlistNames[row]
    }
    
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self;
        let sessionHandler = SessionHandler()
        let session = sessionHandler.getSession()
        setCurrentSession(session!)
    }

    
    
}
