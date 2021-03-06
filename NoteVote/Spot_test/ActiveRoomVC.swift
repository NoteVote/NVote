//
//  ActiveRoomVC.swift
//
//  Created by Dustin Jones on 10/8/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import UIKit
import Parse
import Crashlytics

class ActiveRoomVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ENSideMenuDelegate {


    @IBOutlet weak var tableView: UITableView!
    var refreshControl:UIRefreshControl!
    var reachability: Reachability?

    
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
    
    
    @IBAction func searchButtonPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("ActiveRoom_Search", sender: nil)
    }
	
	//MARK: TableView Delegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    //Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    /*Number of rows of tableView*/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(serverLink.musicList.count == 0){
            do{
                try serverLink.partyObject.fetch()
            }
            catch{
                let alertController = UIAlertController(title: "Party's Over!", message: "The Party has ended.", preferredStyle: UIAlertControllerStyle.Alert)
                let okay = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default){ alertAction in
                    (self.performSegueWithIdentifier("activeRoom_Home", sender: nil))
                }
                alertController.addAction(okay)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
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
        
        cell.backgroundColor = cell.contentView.backgroundColor!
        
        if(!serverLink.musicList.isEmpty){
            let object:PFObject = serverLink.musicList[indexPath.row]
            cell.artistLabel.text! = object.objectForKey("trackArtist") as! String
            cell.songTitle.text! = object.objectForKey("trackTitle") as! String
            cell.songURI = object.objectForKey("uri") as! String
            cell.voteButton.setTitle(String(object.objectForKey("votes") as! Int), forState: UIControlState.Normal)
			
			//initializing cells to voted state or unvoted state.
            let votes = serverLink.songsVoted[(serverLink.partyObject.objectForKey("partyID") as! String)]
            if(votes != nil){
                if (votes!.contains(cell.songURI)){
                    cell.alreadyVoted()
                }
                else{
                    cell.notalreadyVoted()
                }
            }
        }
        return cell
    }
    
    func refresh(sender:AnyObject){
        serverLink.getQueue(){
            (result: [PFObject]) in
            serverLink.musicList = result
            PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"active"], block: nil)
            self.tableView.reloadData()
        }
        self.refreshControl.endRefreshing()
    }
	
	//MARK: Default Methods
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sideMenuController()?.sideMenu?.delegate = self;
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(ActiveRoomVC.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
            self.refresh("")
        } catch {
            print("Unable to create Reachability")
            return
        }
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
        serverLink.currentLocation = nil
        serverLink.musicList = []
        serverLink.songsVotedCheck()
        self.title = serverLink.partyObject.objectForKey("partyName") as? String
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        self.tableView.separatorColor = UIColor.lightGrayColor()
        if reachability != nil{
        }
        else{
            Answers.logCustomEventWithName("Reachability Error", customAttributes: nil)
        }
    }
}
