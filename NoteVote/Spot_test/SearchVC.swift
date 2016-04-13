//
//  SearchVC.swift
//
//  Created by Dustin Jones on 12/1/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import UIKit

class SearchVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ENSideMenuDelegate, UISearchBarDelegate {

    lazy var searchBars:UISearchBar = UISearchBar(frame: CGRectMake(0, 0, 280, 18))
    var preView:String?
    
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
    
    
    @IBOutlet weak var tableView: UITableView!

    @IBAction func BackButtonPressed(sender: UIBarButtonItem) {
        spotifyPlayer.musicOptions = []
        if(preView == "Host"){
            performSegueWithIdentifier("Search_Host", sender: nil)
        }
        else{
            performSegueWithIdentifier("Search_ActiveRoom", sender: nil)
        }
    }
	
	//MARK: SearchBar Delegate
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBars.text! = ""
	}
	
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		if(searchBar.text! != ""){
			searchHandler.Search(searchBar.text!){
				(result: String) in
                if(result != "fail"){
                    spotifyPlayer.setMusicOptions()
                    self.tableView.setContentOffset(CGPoint.zero, animated: true)
                    self.tableView.reloadData()
                }
                else if result == "connect_fail"{
                    let alertController = UIAlertController(title: "Connection Fail", message: "Internet connection was lost. Try searching for songs again later.", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
			}
		}
		searchBar.resignFirstResponder()
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
	}

	//MARK: TableView Delegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spotifyPlayer.musicOptions.count
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("SearchCell", forIndexPath: indexPath) as! SearchTableCell
        
        let customColor = UIView()
        customColor.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = customColor
        
        cell.backgroundColor = cell.contentView.backgroundColor!
        
        cell.songURI = spotifyPlayer.musicOptions[indexPath.row].URI
        if(serverLink.songsVoted.count > 0){
            if(serverLink.songsVoted[serverLink.partyObject.objectForKey("partyID") as! String]!.contains(cell.songURI) || serverLink.songsInBatch.contains(cell.songURI)){
                cell.QueueButton.setBackgroundImage(UIImage(named:"songAdded"), forState: UIControlState.Normal)
                cell.queued = true
            }
            else{
                cell.QueueButton.setBackgroundImage(UIImage(named:"addSong"), forState: UIControlState.Normal)
            }
        }
        cell.songTitle.text! = spotifyPlayer.musicOptions[indexPath.row].Title
        cell.artistLabel.text! = spotifyPlayer.musicOptions[indexPath.row].Artist
        return cell
    }
	
	//MARK: SearchBar Delegate
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        self.resignFirstResponder()
        return true
    }
	
	//MARK: Default Methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.searchBars.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewWillDisappear(animated: Bool) {
        serverLink.addSongBatch(){
            (result:String) in
            if(result == "fail"){
                let alertController = UIAlertController(title: "Uh-oh!", message: "Looks like something went wrong. Song(s) were not added to party.", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            else if result == "connect_fail" {
                let alertController = UIAlertController(title: "Connection Fail", message: "Internet connection was lost. Song(s) were not added to party. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBars = UISearchBar(frame: CGRectMake(0, 0, (self.view.bounds.width * 0.75), 18))
        self.sideMenuController()?.sideMenu?.delegate = self;
		let rightNavBarButton = UIBarButtonItem(customView: searchBars)
		self.navigationItem.rightBarButtonItem = rightNavBarButton
		searchBars.placeholder = "Enter song name"
        searchBars.contentScaleFactor = 2
		searchBars.delegate = self
        searchBars.keyboardAppearance = UIKeyboardAppearance.Dark
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
}
