//
//  SearchVC.swift
//  NVBeta
//
//  Created by uics15 on 12/1/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import UIKit

class SearchVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ENSideMenuDelegate, UISearchBarDelegate {
    lazy   var searchBars:UISearchBar = UISearchBar(frame: CGRectMake(0, 0, 250, 18))
    var preView:String?
    
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
	
	//MARK: SearchBarDelegate
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBars.text! = ""
	}
	
	func searchBarTextDidEndEditing(searchBar: UISearchBar) {
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
	}
	
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		if(searchBar.text! != ""){
			searchHandler.Search(searchBar.text!){
				(result: String) in
				spotifyPlayer.setMusicOptions()

				self.tableView.reloadData()
			}
		}
		searchBar.resignFirstResponder()
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
	}

	//MARK: TableViewDelegate
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
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        self.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.searchBars.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewWillDisappear(animated: Bool) {
        serverLink.addSongBatch()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self;
		let rightNavBarButton = UIBarButtonItem(customView: searchBars)
		self.navigationItem.rightBarButtonItem = rightNavBarButton
		searchBars.placeholder = "Enter song name"
		searchBars.delegate = self
        searchBars.keyboardAppearance = UIKeyboardAppearance.Dark
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
}
