//
//  HostRoomVC.swift
//  NVBeta
//
//  Created by uics15 on 11/5/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import UIKit
import Parse

class HostRoomVC: UIViewController, ENSideMenuDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var albumImage: UIImageView!
    private var labelUpdateCounter = 0
    
    @IBOutlet weak var pinLabel: UILabel!
    private var isAnimating = false
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackArtist: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var dropDownButton: UIButton!
    var dropDownViewIsDisplayed = false
    @IBOutlet weak var dropDownView: UIView!
	@IBOutlet weak var progressView: UIView!
	@IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet var yConstraint: NSLayoutConstraint!
    
	@IBOutlet weak var timeInLabel: UILabel!
	@IBOutlet weak var timeLeftLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    var refreshControl:UIRefreshControl!
    
   //----------Drop Down View Methods----------------
    
    @IBAction func dropDownButtonPressed(sender: UIButton) {
        if(dropDownViewIsDisplayed){
            self.dropDownViewIsDisplayed = false
            self.isAnimating = true
            hideDropDownView()
            
        }
        else{
            self.dropDownViewIsDisplayed = true
            self.isAnimating = true
            showDropDownView()
        }
    }
    
    func hideDropDownView() {
        var frame:CGRect = self.dropDownView.frame
        frame.origin.y = -frame.size.height + 80
        self.animateDropDownToFrame(frame) {
          
        }
    }
    
    func showDropDownView() {
        var frame:CGRect = self.dropDownView.frame
        frame.origin.y = 64
        self.animateDropDownToFrame(frame) {
            
        }
        serverLink.getQueue(){
            (result: [PFObject]) in
            PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"active"], block: nil)
            serverLink.sortMusicList()
            self.tableView.reloadData()
        }
    }
    
    func animateDropDownToFrame(frame: CGRect, completion:() -> Void) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8, options: [], animations: {
            self.dropDownView.frame = frame
            }, completion:  { finished in
                if(self.dropDownViewIsDisplayed){
                    self.yConstraint.constant = -frame.size.height
                }
                else{
                    self.yConstraint.constant = -14
                }
                self.isAnimating = false
            })
    }
    
    
//----------Table View Methods----------------
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    //Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    /*Number of rows of tableView*/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(String(serverLink.musicList.count) + " cells allowed")
        return serverLink.musicList.count
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    /*Creating tableview cells*/
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("hostCell", forIndexPath: indexPath) as! HostTableCell
        
        let customColor = UIView()
        customColor.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = customColor
        
        if(!serverLink.musicList.isEmpty){
            print(String(serverLink.musicList.count) + " cells to build")
            let object:PFObject = serverLink.musicList[indexPath.row]
            cell.artistLabel.text! = object.objectForKey("trackArtist") as! String
            cell.songTitle.text! = object.objectForKey("trackTitle") as! String
            cell.songURI = object.objectForKey("uri") as! String
            cell.voteButton.setTitle(String(object.objectForKey("votes") as! Int), forState: UIControlState.Normal)
            
            //initializing cells to voted state or unvoted state.
            let votes = serverLink.getSongsVoted()
            if (votes.contains(cell.songURI)){
                cell.alreadyVoted()
            }
            else{
                cell.notalreadyVoted()
            }
        }
        return cell
    }
    
    func refresh(sender:AnyObject)
    {
        serverLink.getQueue(){
            (result: [PFObject]) in
            PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"active"], block: nil)
            serverLink.sortMusicList()
            print(serverLink.musicList)
            self.tableView.reloadData()
        }
        self.refreshControl.endRefreshing()
    }
    
    
    
    
    
//----------Nav Bar / Side Menu Items----------------
    
    @IBAction func SearchButtonPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("Host_Search", sender: nil)
    }
    
    // MARK: - ENSideMenu Delegate
    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
		let menu = self.sideMenuController()?.sideMenu?.menuViewController as! MyMenuTableViewController
		menu.options("Host")
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
    
    
    
    
    
//----------Spotify/Music Playing in general----------------
    
    @IBAction func playPausePressed(sender: AnyObject) {
        if (spotifyPlayer.player!.isPlaying) {
            spotifyPlayer.player!.setIsPlaying(false, callback: { (error:NSError!) -> Void in
                if error != nil {
                    print("Enabling playback got error \(error)")
                    return
                }
            })
            playPauseButton.setBackgroundImage(UIImage(named:"PlayButton"), forState: UIControlState.Normal)
            
        } else {
            spotifyPlayer.player!.setIsPlaying(true, callback: { (error:NSError!) -> Void in
                if error != nil {
                    print("Enabling playback got error \(error)")
                    return
                }
            })
            playPauseButton.setBackgroundImage(UIImage(named: "PauseButton"), forState: UIControlState.Normal)
        }
    }
    
    
    
    
    func startSession(){
        let sessionHandler = SessionHandler()
        let session = sessionHandler.getSession()
        spotifyPlayer.playUsingSession(session)
    }
    
    func handleMetadata() {
        trackTitle.text = spotifyPlayer.trackTitle!
        trackArtist.text = spotifyPlayer.trackArtist!
    }
    
    func handleArt() {
    
        albumImage.image = spotifyPlayer.albumArt!
    }
	
	func updateProgress() {
        
        if (spotifyPlayer.player?.currentTrackDuration == nil) { return }
        
        let length = (spotifyPlayer.player?.currentTrackDuration)! as Double
        let position = (spotifyPlayer.player?.currentPlaybackPosition)! as Double
        
        //use position values to ensure that there is no NaN errors
        if (position > 0 && position <= length) {
			
            //find the value of the minute field
            let posInMin = (position/60) % 60
            ///find the value of the minute field
            let lengthInMin = (length-position)/60 % 60

            //If drop down menu is showing don't update.
            if(!isAnimating){
                //display the minute field and the second field, rounted to integers
                timeInLabel.text! = String(format: "%1d:%02d-", Int(posInMin), Int(position)%60)
                
                //display the minute field and the second field, rounded to integers
                timeLeftLabel.text! = String(format: "-%1d:%02d", Int(lengthInMin), Int((length-position)%60))
            }
            //draw the progress bar
			let width = position/length
            progressBar.setProgress(Float(width),animated: true)

            
        }
	}
    
    
    
    
//----------Methods for enter/exit HostVC----------------
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        let currentRoom = userDefaults.objectForKey("currentRoom") as! String
        self.title = currentRoom
        if(userDefaults.objectForKey("partyPin") as? String != nil){
            self.pinLabel.text = userDefaults.objectForKey("partyPin") as? String
        }
        if(spotifyPlayer.trackArtist != nil){
            self.trackArtist.text = spotifyPlayer.trackArtist
            self.trackTitle.text = spotifyPlayer.trackTitle
            self.albumImage.image = spotifyPlayer.albumArt
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let view:String = "Host"
        let destinationVC = segue.destinationViewController as! SearchVC
        destinationVC.preView = view
		hideSideMenuView()
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        serverLink.isHosting = true
        self.sideMenuController()?.sideMenu?.delegate = self;
        startSession()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        
        let width:CGFloat = self.dropDownView.frame.size.width
        self.dropDownView.frame = CGRectMake(0, self.view.bounds.height/2, width, self.view.bounds.height)
        
        
    
        //Notification observer for track metadata
        let defaultCenter = NSNotificationCenter.defaultCenter()
        defaultCenter.addObserver(self, selector: "handleMetadata", name: "MetadataChangeNotification", object: nil)
        //Notification observer for album art
        defaultCenter.addObserver(self, selector: "handleArt", name: "ArtNotification", object: nil)
		
		//displaylink for progress bar
		let displayLink = CADisplayLink(target: self, selector: "updateProgress")
		displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
		
        //increase progress bar size
		let transform = CGAffineTransformMakeScale(1.0, 3.0)
		progressBar.transform = transform
		
    }
}
