//
//  HomeVC.swift
//
//  Created by Aaron Kaplan on 9/29/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import UIKit
import Parse
import Crashlytics
import CoreLocation

class HomeVC: UIViewController, ENSideMenuDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
	
	private let authController = SpotifyAuth()
	private let spotifyAuthenticator = SPTAuth.defaultInstance()
	private var user:SPTUser? = nil
	var roomsNearby:[PFObject] = []
    var refreshControl:UIRefreshControl!
    var password:UITextField!
    var locationManager = CLLocationManager()

    @IBOutlet weak var activityRunningLabel: UILabel!
    @IBOutlet weak var activityRunning: UIActivityIndicatorView!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - ENSideMenu Delegate
    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
		let menu = self.sideMenuController()?.sideMenu?.menuViewController as! MyMenuTableViewController
		menu.options("Home")
		
    }
    
    func sideMenuWillClose() {
        print("sideMenuWillClose")
    }
    
    func sideMenuShouldOpenSideMenu() -> Bool {
        print("sideMenuShouldOpenSideMenu")
        return true
    }
    
    func sideMenuDidClose() {
        print("sideMenuDidClose")
    }
    
    func sideMenuDidOpen() {
        print("sideMenuDidOpen")
    }
	

    @IBAction func menuButtonPressed(sender: AnyObject) {
        toggleSideMenuView()
    }
    
    @IBAction func addButtonPressed(sender: UIBarButtonItem) {
        
        self.tableView.hidden = true
        self.activityRunningLabel.hidden = false
        self.activityRunning.startAnimating()
		
		let sessionHandler = SessionHandler()
		let session = sessionHandler.getSession()
		
		if (user != nil) {
			if (user!.product.rawValue == 2){
				authController.setPremiumParameters(spotifyAuthenticator)
				
				spotifyAuthenticator.renewSession(session, callback:{
					(error: NSError?, session:SPTSession?) -> Void in
					
					if(error == nil){
						
						sessionHandler.storeSession(session!)
						if(session!.isValid()){
                            self.tableView.hidden = false
                            self.activityRunning.stopAnimating()
                            self.activityRunningLabel.hidden = true
							self.performSegueWithIdentifier("Home_CreateRoom", sender: nil)
						}
						
					} else {
						Answers.logCustomEventWithName("Authentication Error", customAttributes:["Code":error!])
                        
                        self.tableView.hidden = false
                        self.activityRunning.stopAnimating()
                        self.activityRunningLabel.hidden = true
						let alertController = UIAlertController(title: "Uh-oh!", message: "Looks like something went wrong. Please try again in a minute.", preferredStyle: UIAlertControllerStyle.Alert)
						alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
						self.presentViewController(alertController, animated: true, completion: nil)

					}
				})
				
			} else {
                self.tableView.hidden = false
                self.activityRunning.stopAnimating()
                self.activityRunningLabel.hidden = true
				let alertController = UIAlertController(title: "Spotify Account", message:
					"To Create and Host your own room you must be a Premium member of Spotify", preferredStyle: UIAlertControllerStyle.Alert)
				alertController.addAction(UIAlertAction(title: "No Thanks", style: UIAlertActionStyle.Destructive,handler: nil))
				alertController.addAction(UIAlertAction(title: "Upgrage", style: UIAlertActionStyle.Default) {
					(action) in
					print("Divert to spotify website")
					Answers.logCustomEventWithName("Upgrade", customAttributes: nil)
					})
				
				self.presentViewController(alertController, animated: true, completion: nil)
			}
		}
    }
	
	//MARK: TableView Delegate
	
    //Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    /*Number of rows of tableView*/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(roomsNearby.count < 1 && serverLink.currentLocation != nil){
            let alertController = UIAlertController(title: "No Parties Nearby", message: "There are no parites near you. Would you like to look again?", preferredStyle: UIAlertControllerStyle.Alert)
            let no = UIAlertAction(title: "No", style: UIAlertActionStyle.Destructive){ alertAction in
                
            }
            let yes = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default){ alertAction in
                if(serverLink.currentLocation != nil){
                    serverLink.findRooms(){
                        (result: [PFObject]) in
                        self.roomsNearby = result
                        self.tableView.reloadData()
                    }
                    self.refreshControl.endRefreshing()
                }
            }
            alertController.addAction(no)
            alertController.addAction(yes)
            self.presentViewController(alertController, animated: true, completion: nil)
            return 0
        }
        else{
            return self.roomsNearby.count
        }
    }
    
    /*CurrentPlayer Selected and moves to next page*/
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        serverLink.setParty(self.roomsNearby[indexPath.row])
        if(serverLink.partyObject.objectForKey("partyPrivate") as! Bool){
            let alertController = UIAlertController(title: "This Party is Private", message: "Enter the 4 digit party pin below.", preferredStyle: UIAlertControllerStyle.Alert)
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive){ alertAction in
                
            }
            let enter = UIAlertAction(title: "Enter", style: UIAlertActionStyle.Default){ alertAction in
                if(self.password.text! == serverLink.partyObject.objectForKey("partyPin") as! String){
                    self.performSegueWithIdentifier("Home_ActiveRoom", sender: nil)
                }
            }
            alertController.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
                textField.clearsOnBeginEditing = true
                textField.placeholder = "Room Pin"
                self.password = textField
                textField.keyboardAppearance = UIKeyboardAppearance.Dark
                textField.keyboardType = UIKeyboardType.DecimalPad
            }
            alertController.addAction(cancel)
            alertController.addAction(enter)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else{
            self.performSegueWithIdentifier("Home_ActiveRoom", sender: nil)
        }
    }
    
    
    /*Creating tableview cells*/
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! HomeTableCell
        
        let customColor = UIView()
        customColor.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = customColor
        cell.roomName.text = roomsNearby[indexPath.row].objectForKey("partyName") as? String
        let roomLocation = roomsNearby[indexPath.row].objectForKey("geoLocation") as? PFGeoPoint
        if(roomLocation != nil){
            let distance:Double = serverLink.currentLocation!.distanceInMilesTo(roomLocation!)
            let distanceString = NSString(format: "%.2f", distance)
            cell.roomDistance.text = String(distanceString) + " mi"
        }
        return cell
    }
    
    func refresh(sender:AnyObject){
        if(serverLink.currentLocation != nil){
            serverLink.findRooms(){
                (result: [PFObject]) in
                self.roomsNearby = result
                self.tableView.reloadData()
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    //MARK: CLLocation Delegate Methods
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors with Location: " + error.localizedDescription)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        if(location != nil){
            let currentLocation:PFGeoPoint = PFGeoPoint(latitude: Double(location!.coordinate.latitude), longitude: Double(location!.coordinate.longitude))
            if(serverLink.currentLocation == nil){
                serverLink.currentLocation = currentLocation
                serverLink.findRooms(){
                    (result: [PFObject]) in
                    self.roomsNearby = result
                    self.tableView.reloadData()
                }
            }
            serverLink.currentLocation = currentLocation
        }
    }

    //MARK: Default Methods
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        serverLink.findRooms(){
            (result: [PFObject]) in
            self.roomsNearby = result
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		let sessionHandler = SessionHandler()
		let session = sessionHandler.getSession()
        
        //Geolocation
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
		
		//Get user data
		SPTUser.requestCurrentUserWithAccessToken(session!.accessToken, callback: {
			(error:NSError!, result:AnyObject!) -> Void in
			
			self.user = result as? SPTUser
		})
		
        //Checking to see if roomsNearby has all items in songsVoted keys
        self.sideMenuController()?.sideMenu?.delegate = self;
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		hideSideMenuView()
        self.locationManager.stopUpdatingLocation()
	}
}
