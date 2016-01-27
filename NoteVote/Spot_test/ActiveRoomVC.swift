//
//  ActiveRoomVC.swift
//  NVBeta
//
//  Created by Dustin Jones on 10/8/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import UIKit
import Parse

class ActiveRoomVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ENSideMenuDelegate {


    @IBOutlet weak var tableView: UITableView!
    var refreshControl:UIRefreshControl!

    
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
    
    
    @IBAction func searchButtonPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("ActiveRoom_Search", sender: nil)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    //Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    /*Number of rows of tableView*/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverLink.musicList.count
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    /*Creating tableview cells*/
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("songCell", forIndexPath: indexPath) as! QueueTableCell
        
        let customColor = UIView()
        customColor.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = customColor
        if(!serverLink.musicList.isEmpty){
            let object:PFObject = serverLink.musicList[indexPath.row]
            cell.artistLabel.text! = object.objectForKey("trackArtist") as! String
            cell.songTitle.text! = object.objectForKey("trackTitle") as! String
            cell.songURI = object.objectForKey("uri") as! String
            cell.voteButton.setTitle(String(object.objectForKey("votes") as! Int), forState: UIControlState.Normal)
            //initializing cells to voted state or unvoted state.
            let votes = serverLink.songsVoted[(userDefaults.objectForKey("roomID") as! String)]
            if(votes != nil){
                if (votes!.contains(cell.songURI)){
                    cell.alreadyVoted()
                }
                else{
                    cell.notalreadyVoted()
                }
            }
        }
        
        //TODO: somehow link to prototype cell QueueTableCell.swift
        return cell
    }
    
    func refresh(sender:AnyObject)
    {
        serverLink.getQueue(){
            (result: [PFObject]) in
            serverLink.musicList = result
            PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"active"], block: nil)
            serverLink.sortMusicList()
            self.tableView.reloadData()
        }
        self.refreshControl.endRefreshing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self;
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }

  
    @IBAction func exitButtonPressed(sender: UIBarButtonItem) {
        //TODO: remember votes and remove user from room on server
        performSegueWithIdentifier("activeRoom_Home", sender: nil)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue == "ActiveRoom_Search"){
            let view:String = "ActiveRoom"
            let destinationVC = segue.destinationViewController as! SearchVC
            destinationVC.preView = view
        }
    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        serverLink.musicList = []
        serverLink.songsVotedCheck()
        self.title = userDefaults.objectForKey("currentRoom") as! String
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        self.tableView.separatorColor = UIColor.lightGrayColor()
        serverLink.getQueue(){
            (result: [PFObject]) in
            serverLink.musicList = result
			PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"active"], block: nil)
            serverLink.sortMusicList()
            self.tableView.reloadData()
        }
        
    }
}
