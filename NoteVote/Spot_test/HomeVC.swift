//
//  HomeVC.swift
//  NVBeta
//
//  Created by uics15 on 9/29/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import UIKit
import Parse

class HomeVC: UIViewController, ENSideMenuDelegate, UITableViewDataSource, UITableViewDelegate{
    
    var roomsNearby:[PFObject] = []
    var refreshControl:UIRefreshControl!
    
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
        performSegueWithIdentifier("Home_CreateRoom", sender: nil)
    }
    
    
    //Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    /*Number of rows of tableView*/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomsNearby.count
        //TODO: needs to return the number of rooms in the area.
    }
    
    /*CurrentPlayer Selected and moves to next page*/
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        userDefaults.setObject(self.roomsNearby[indexPath.row].objectForKey("partyID") as! String, forKey: "roomID")
        //takes name of current room and saves it.
        userDefaults.setObject(self.roomsNearby[indexPath.row].objectForKey("partyName") as! String, forKey: "currentRoom")
        userDefaults.synchronize()
        self.performSegueWithIdentifier("Home_ActiveRoom", sender: nil)
        
    }
    
    
    /*Creating tableview cells*/
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        let customColor = UIView()
        customColor.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = customColor
        
        cell.textLabel!.textColor = UIColor(red: 125/255, green: 205/255, blue: 3/255, alpha: 1.0)
        cell.textLabel?.text = roomsNearby[indexPath.row].objectForKey("partyName") as? String
        cell.textLabel?.font = UIFont.systemFontOfSize(30)
        //TODO: set cell atributes.
        return cell
    }
    
    func refresh(sender:AnyObject)
    {
        serverLink.findRooms(){
            (result: [PFObject]) in
            self.roomsNearby = result
            self.tableView.reloadData()
        }
        self.refreshControl.endRefreshing()
    }
    
    // _____ Default View Controller Methods _____
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        //Handles result from completion handler.
        serverLink.findRooms(){
            (result: [PFObject]) in
            self.roomsNearby = result
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Checking to see if roomsNearby has all items in songsVoted keys
        self.sideMenuController()?.sideMenu?.delegate = self;
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		hideSideMenuView()
	}
}
