//
//  HostRoomVC.swift
//  NVBeta
//
//  Created by uics15 on 11/5/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import UIKit
import Parse

class HostRoomVC: UIViewController, SPTAudioStreamingPlaybackDelegate, ENSideMenuDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackArtist: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var dropDownButton: UIButton!
    var dropDownViewIsDisplayed = false
    @IBOutlet weak var dropDownView: UIView!
    private var player:SPTAudioStreamingController?
    private let authController = SpotifyAuth()
    
    @IBOutlet weak var tableView: UITableView!
    var refreshControl:UIRefreshControl!
    
    
    
//----------Drop Down View Methods----------------
    
    @IBAction func dropDownButtonPressed(sender: UIButton) {
        if(dropDownViewIsDisplayed){
            self.dropDownViewIsDisplayed = false
            //dropDownButton.setBackgroundImage(UIImage(named: "dropDown"), forState: UIControlState.Normal)
            hideDropDownView()
        }
        else{
            self.dropDownViewIsDisplayed = true
            //dropDownButton.setBackgroundImage(UIImage(named: "dropUp"), forState: UIControlState.Normal)
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
            //serverLink.musicList = result
            PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"active"], block: nil)
            serverLink.sortMusicList()
            self.tableView.reloadData()
        }
    }
    
    func animateDropDownToFrame(frame: CGRect, completion:() -> Void) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8, options: [], animations: {
            self.dropDownView.frame = frame
            }, completion:  { finished in
//                if(self.dropDownViewIsDisplayed){
//                    self.dropDownButton.setBackgroundImage(UIImage(named: "dropUp"), forState: UIControlState.Normal)
//                }
//                else{
//                    self.dropDownButton.setBackgroundImage(UIImage(named: "dropDown"), forState: UIControlState.Normal)
//                }
                
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
            //serverLink.musicList = result
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
        if (self.player!.isPlaying) {
            self.player!.setIsPlaying(false, callback: { (error:NSError!) -> Void in
                if error != nil {
                    print("Enabling playback got error \(error)")
                    return
                }
            })
            playPauseButton.setBackgroundImage(UIImage(named:"PlayButton"), forState: UIControlState.Normal)
            
        } else {
            self.player!.setIsPlaying(true, callback: { (error:NSError!) -> Void in
                if error != nil {
                    print("Enabling playback got error \(error)")
                    return
                }
            })
            playPauseButton.setBackgroundImage(UIImage(named: "PauseButton"), forState: UIControlState.Normal)
        }
    }
    
    
    func playUsingSession(sessionObj:SPTSession!){
   
        let kClientID = authController.getClientID()
        
        if player == nil {
            player = SPTAudioStreamingController(clientId: kClientID)
            player?.playbackDelegate = self
        }
        
        player?.loginWithSession(sessionObj, callback: { (error:NSError!) -> Void in
            if error != nil {
                print("Enabling playback got error \(error)")
                return
            }
            
            serverLink.syncGetQueue()
            PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"host"], block: nil)
            var currentTrack:String = ""
            if !serverLink.musicList.isEmpty {
                //TODO dynamic track URI
                currentTrack = serverLink.pop()
              
            } else {
                if(!serverLink.playlistMusic.isEmpty){
                    currentTrack = serverLink.playlistMusic.removeFirst()
                    serverLink.playlistMusic.append(currentTrack)
                }
            }
            if(currentTrack != ""){
                self.player?.playURI(NSURL(string: currentTrack), callback: { (error:NSError!) -> Void in
                    if error != nil {
                        print("Track lookup got error \(error)")
                        return
                    }
                    
                })
            }
            
        })
    }
    
    
    //fires whenever the track changes
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        if (trackMetadata == nil || trackMetadata["SPTAudioStreamingMetadataTrackURI"] as! String == serverLink.currentURI){
            
            //TODO: SELECT SONGS ON VOTES, SOMEHOW IMPLEMENT PLAYLIST INTEGRATION
            serverLink.syncGetQueue()
            PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"host"], block: nil)
            
            let currentTrack:String!
            if (!serverLink.musicList.isEmpty) {
                currentTrack = serverLink.pop()
				
            } else {
                currentTrack = serverLink.playlistMusic.removeFirst()
                serverLink.playlistMusic.append(currentTrack)
            }
            self.player?.playURI(NSURL(string: currentTrack), callback: { (error:NSError!) -> Void in
                if error != nil {
                    print("Track lookup got error \(error)")
                    return
                }
            })
        } else {
            let albumURI = trackMetadata["SPTAudioStreamingMetadataAlbumURI"] as! String
            trackTitle.text! = trackMetadata["SPTAudioStreamingMetadataTrackName"] as! String
            trackArtist.text! = trackMetadata["SPTAudioStreamingMetadataArtistName"] as! String
			serverLink.currentURI = trackMetadata["SPTAudioStreamingMetadataTrackURI"] as! String
            serverLink.trackTitle = trackTitle.text!
            serverLink.artistName = trackArtist.text!
            
            SPTAlbum.albumWithURI(NSURL(string: albumURI), session: nil) { (error:NSError!, albumObj:AnyObject!) -> Void in
                let album = albumObj as! SPTAlbum
                
                
                //TODO: I dont understand this dispatch async thing
                
                if let imgURL = album.largestCover.imageURL as NSURL! {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        let error:NSError? = nil
                        var coverImage = UIImage()
                        
                       if let imageData = NSData(contentsOfURL: imgURL){
                            
                            if error == nil {
                                coverImage = UIImage(data: imageData)!
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.albumImage.image = coverImage
                            serverLink.albumArt = coverImage
                        })
                    })
                }
            }
        }

    }
    func startSession(){
        let sessionHandler = SessionHandler()
        let session = sessionHandler.getSession()
        playUsingSession(session)
    }
    
    
    
//----------Methods for enter/exit HostVC----------------
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        let currentRoom = userDefaults.objectForKey("currentRoom") as! String
        self.title = currentRoom
        if(serverLink.artistName != nil){
            self.trackArtist.text = serverLink.artistName
            self.trackTitle.text = serverLink.trackTitle
            self.albumImage.image = serverLink.albumArt
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
        self.sideMenuController()?.sideMenu?.delegate = self;
        //if !serverLink.musicList.isEmpty {
            startSession()
        //}
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        let width:CGFloat = self.dropDownView.frame.size.width
        self.dropDownView.frame = CGRectMake(0, self.view.bounds.height/2, width, self.view.bounds.height)
    }
}
