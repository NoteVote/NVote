//
//  MyMenuTableViewController.swift
//  SwiftSideMenu
//
//  Created by Evgeny Nazarov on 29.09.14.
//  Copyright (c) 2014 Evgeny Nazarov. All rights reserved.
//

import UIKit

class MyMenuTableViewController: UITableViewController {
    var selectedMenuItem : Int = 0
    var menuOptions:[String] = ["Log out"]
    
	
	func options(view: String){
		if view == "Host" {
			self.menuOptions = ["Close Room"]
		} else {
			self.menuOptions = ["Log out"]
		}
		self.tableView.reloadData()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize apperance of table view
        tableView.contentInset = UIEdgeInsetsMake(70.0, 0, 0, 0) //
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 0.8)
        tableView.scrollsToTop = false
        
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        tableView.selectRowAtIndexPath(NSIndexPath(forRow: selectedMenuItem, inSection: 0), animated: false, scrollPosition: .Middle)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("CELL")
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "CELL")
            cell!.backgroundColor = UIColor.clearColor()
            cell!.textLabel?.textColor = UIColor.greenColor()
            let selectedBackgroundView = UIView(frame: CGRectMake(0, 0, cell!.frame.size.width, cell!.frame.size.height))
            selectedBackgroundView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.2)
            cell!.selectedBackgroundView = selectedBackgroundView
        }
        
        cell!.textLabel?.text = menuOptions[indexPath.row]
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        print("did select row: \(indexPath.row)")
        
        if (indexPath.row == selectedMenuItem) {
			//return
        }
        
        selectedMenuItem = indexPath.row
        
        //Present new view controller
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
        var destViewController : UIViewController
        switch (indexPath.row) {
        case 0:
			if menuOptions[indexPath.row] == "Close Room" {
				destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Home")
				serverLink.deleteRoom()
				serverLink.currentURI = ""
			} else { //if equal to "Log out"
				destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Login")
				userDefaults.removeObjectForKey("session")
			}
            break
		default:
            destViewController = mainStoryboard.instantiateViewControllerWithIdentifier("ViewController4") 
            break
        }
		
		sideMenuController()?.setContentViewController(destViewController)
    }
    

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		print("segue")
		segue.destinationViewController
	}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
