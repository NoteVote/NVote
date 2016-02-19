//
//  CreateRoomVC.swift
//
//  Created by Dustin Jones on 10/8/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import UIKit
import Parse
import Crashlytics


class CreateRoomVC: UIViewController, ENSideMenuDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    let sessionHandler = SessionHandler()
	private var currentPickerRow = 0
    var session:SPTSession? = nil
    @IBOutlet weak var roomName: UITextField!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var privateParty:Bool = false
    var playlistNames:[String] = []
	
	// MARK: ENSideMenu Delegate
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        roomName.resignFirstResponder()
    }
    
	//MARK: Page Options
	
    @IBAction func infoButtonPressed(sender: UIButton) {
        let alertController = UIAlertController(title: "Playlist Info", message:
            "Choosing a playlist to pull music from when no music is in your party queue. It keeps the party going.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    @IBAction func privateSwitchSwitched(sender: UISwitch) {
        self.privateParty = !self.privateParty
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("CreateRoom_Home", sender: nil)
    }
    	
    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
		
		//TODO: Delete any existing rooms. (Doesn't work because PartyID is nil)
		//serverLink.deleteRoomNow()
		
		serverLink.musicList = []
        serverLink.songsVoted[session!.canonicalUsername] = []
        serverLink.addParty(roomName.text!, partyID: session!.canonicalUsername, priv: privateParty)
        userDefaults.setObject(roomName.text!, forKey: "currentRoom")
        userDefaults.setObject(session!.canonicalUsername, forKey: "roomID")
        userDefaults.synchronize()
		
		//Playlist Selection and Conversion
        if(!playlistNames.isEmpty){
            spotifyPlayer.playlistToTracks(currentPickerRow)
        }
		
		//log who created a room
		Answers.logCustomEventWithName("Room Created", customAttributes: ["user":session!.canonicalUsername])
		
        self.performSegueWithIdentifier("CreateRoom_HostRoom", sender: nil)
        
    }
    
    func setCurrentSession(session: SPTSession) {
        self.session = session
    }
    
	//MARK: PickerView Delegate
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.playlistNames.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }

    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var attributedString: NSAttributedString!
        attributedString = NSAttributedString(string: self.playlistNames[row], attributes: [NSForegroundColorAttributeName : UIColor(colorLiteralRed: 125/255, green: 205/255, blue: 3/255, alpha: 1.0)])
        return attributedString
    }

	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		currentPickerRow = row
	}
    
	
	//MARK: Default Methods
	
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self;
        let sessionHandler = SessionHandler()
        let session = sessionHandler.getSession()
		
		//TODO: why are we setting current session?
        setCurrentSession(session!)
        self.playlistNames.removeAll()
		searchHandler.playlistData.removeAll()
		
		searchHandler.getPlaylists(){
			(result: String) in
			
			for x in searchHandler.playlistData {
				self.playlistNames.append(x.0)
			}
			self.pickerView.reloadAllComponents()
		}

    }
	
	
}
