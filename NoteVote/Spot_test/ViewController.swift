//
//  ViewController.swift
//  
//  This class is a view controller for the login screen and handles user login.
//
//  Created by Aaron Kaplan on 9/22/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import UIKit
import Crashlytics

class ViewController: UIViewController, SPTAuthViewDelegate {
	
    private let sessionHandler = SessionHandler()
    private var authController = SpotifyAuth()
    private let spotifyAuthenticator = SPTAuth.defaultInstance()
    private var currentSession: SPTSession? = nil
	private var user:SPTUser? = nil
	
	@IBOutlet weak var spotPremium: UILabel!
    @IBOutlet weak var buttonHeight: NSLayoutConstraint!
    @IBOutlet weak var LogInLabel: UILabel!
    @IBOutlet weak var activityRunning: UIActivityIndicatorView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var findPartyButton: UIButton!
    
    //MARK: SPTAuthView Delegate
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
		
		currentSession = session
		
		//Get user data
		SPTUser.requestCurrentUserWithAccessToken(session!.accessToken, callback: {
			(error:NSError!, result:AnyObject!) -> Void in
			
			self.user = result as? SPTUser
			
			let notificationCenter = NSNotificationCenter.defaultCenter()
			notificationCenter.postNotificationName("UserDataNotification", object: nil)
		})
		
		
    }
	
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        endLoading()
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
		Answers.logCustomEventWithName("Authentication Fail", customAttributes:["Type":"Initial"])
    }
    
    
    //MARK: GUI Actions
    
    @IBAction func loginWithSpotify(sender: AnyObject) {
        
        authController.setParameters(spotifyAuthenticator)
        
        let session = sessionHandler.getSession()
		
		startLoading()
		
		if (session != nil) {
			
			//move on with session
            if (session!.isValid()) {
				
                currentSession = session
				
				//Get user data
				SPTUser.requestCurrentUserWithAccessToken(session!.accessToken, callback: {
					(error:NSError!, result:AnyObject!) -> Void in
					
					self.user = result as? SPTUser
					
					let notificationCenter = NSNotificationCenter.defaultCenter()
					notificationCenter.postNotificationName("UserDataNotification", object: nil)
                    return
                })
            } else {
				
				//renew session
                spotifyAuthenticator.renewSession(session, callback:{
                    (error: NSError?, session:SPTSession?) -> Void in
                    
                    if(error == nil){
                        self.currentSession = session
						
                        if(session!.isValid()){
							
							//Get user data
							SPTUser.requestCurrentUserWithAccessToken(session!.accessToken, callback: {
								(error:NSError!, result:AnyObject!) -> Void in
								
								self.user = result as? SPTUser
								
								let notificationCenter = NSNotificationCenter.defaultCenter()
								notificationCenter.postNotificationName("UserDataNotification", object: nil)
							})
							
							
							//self.performSegueWithIdentifier("start_Party", sender: nil)
                        }
                        
                    } else {
                        Answers.logCustomEventWithName("Authentication Error", customAttributes:["Type":"Renew"])
                    }
                })
            }
        }
        else{
            
            self.authController = SpotifyAuth()
			//set default instance parameters
			authController.setParameters(spotifyAuthenticator)
			
            let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
            spotifyAuthenticationViewController.delegate = self
            spotifyAuthenticationViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            spotifyAuthenticationViewController.definesPresentationContext = true
            presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)
        }
    }
    

    @IBAction func findPartyButtonPressed(sender: UIButton) {
        performSegueWithIdentifier("find_Party", sender: nil)
    }
    
    
    //MARK: Additional Methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "start_Party"){
            sessionHandler.storeSession(currentSession!)
        }
    }
    
	func startLoading() {
		self.LogInLabel.hidden = false
		self.spotPremium.hidden = true
		self.loginButton.hidden = true
		self.findPartyButton.hidden = true
		self.activityRunning.startAnimating()
	}
	
	func endLoading() {
		self.activityRunning.stopAnimating()
		self.LogInLabel.hidden = true
		self.spotPremium.hidden = false
		self.loginButton.hidden = false
		self.findPartyButton.hidden = false
	}

	func handleUserData() {
		
		endLoading()
		
		if user != nil {
			switch user!.product.rawValue {
				//free user
				case 1:
					let alertController = UIAlertController(title: "Spotify Account", message: "To create a room, you must have a Spotify Premium account. Please upgrade your account to use this feature.", preferredStyle: UIAlertControllerStyle.Alert)
					alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
					
					self.presentViewController(alertController, animated: true, completion: nil)
					
					Answers.logCustomEventWithName("Account Error", customAttributes: ["Account Level" : user!.product.rawValue])
                    userDefaults.removeObjectForKey("session")
                    userDefaults.synchronize()
					
					break
			
				//premium user
				case 2:
					self.performSegueWithIdentifier("start_Party", sender: nil)
					break
				
				//unlimited user (also free)
				case 3:
					let alertController = UIAlertController(title: "Spotify Account", message: "To create a room, you must have a Spotify Premium account. Please upgrade your account to use this feature.", preferredStyle: UIAlertControllerStyle.Alert)
					alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
					
					self.presentViewController(alertController, animated: true, completion: nil)

					
					Answers.logCustomEventWithName("Account Error", customAttributes: ["Account Level" : user!.product.rawValue])
                    
                    userDefaults.removeObjectForKey("session")
                    userDefaults.synchronize()
					
					break
				
				//unknown user or other value
				default:
					let alertController = UIAlertController(title: "Spotify Account", message: "There was a problem authorizing your account through Spotify. Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
					alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
					
					self.presentViewController(alertController, animated: true, completion: nil)
					
					Answers.logCustomEventWithName("Account Error", customAttributes: ["Account Level" : user!.product.rawValue])
                    
                    userDefaults.removeObjectForKey("session")
                    userDefaults.synchronize()

					break
			
			}
		} else {
			
			let alertController = UIAlertController(title: "Spotify Account", message: "There was a problem authorizing your account through Spotify. Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
			alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Destructive,handler: nil))
			
			self.presentViewController(alertController, animated: true, completion: nil)

			Answers.logCustomEventWithName("Get User Error", customAttributes: nil)
            
            userDefaults.removeObjectForKey("session")
            userDefaults.synchronize()
		}
	}
	
    //MARK: Default Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginButton.layer.cornerRadius = 15
        self.findPartyButton.layer.cornerRadius = 15
        self.buttonHeight.constant = (self.view.bounds.size.height * 0.25)
		
		let defaultCenter = NSNotificationCenter.defaultCenter()
		defaultCenter.addObserver(self, selector: #selector(ViewController.handleUserData), name: "UserDataNotification", object: nil)
		
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }

    override func viewDidAppear(animated: Bool) {

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



}

