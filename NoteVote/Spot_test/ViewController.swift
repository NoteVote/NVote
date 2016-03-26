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
    private let authController = SpotifyAuth()
    private let spotifyAuthenticator = SPTAuth.defaultInstance()
    private var currentSession: SPTSession? = nil
    
    @IBOutlet weak var LogInLabel: UILabel!
    @IBOutlet weak var activityRunning: UIActivityIndicatorView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    
    
    //MARK: SPTAuthView Delegate
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {

        setSession(session)
        performSegueWithIdentifier("segueOne", sender: nil)
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {

    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
		Answers.logCustomEventWithName("Authentication Error", customAttributes:["Code":error!])
    }
    
    
    //MARK: GUI Actions
    
    @IBAction func loginWithSpotify(sender: AnyObject) {
        
        authController.setParameters(spotifyAuthenticator)
        
        let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
        spotifyAuthenticationViewController.delegate = self
        spotifyAuthenticationViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        spotifyAuthenticationViewController.definesPresentationContext = true
        presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)
    }
    
    
    //MARK: Additional Methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueOne"){
            sessionHandler.storeSession(currentSession!)

        }
    }
    
    func setSession(session: SPTSession) {
        currentSession = session
    }


    //MARK: Default Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let session = sessionHandler.getSession()
        
        if (session != nil) {
            if (session!.isValid()) {
                setSession(session!)
            } else {
                self.LogInLabel.hidden = false
                self.loginButton.hidden = true
                self.activityRunning.startAnimating()
				authController.setParameters(spotifyAuthenticator)

				spotifyAuthenticator.renewSession(session, callback:{
					(error: NSError?, session:SPTSession?) -> Void in
					
					if(error == nil){
                        self.setSession(session!)
						
                        if(session!.isValid()){
                            self.activityRunning.stopAnimating()
                            self.LogInLabel.hidden = true
                            self.loginButton.hidden = false
                            self.performSegueWithIdentifier("segueOne", sender: nil)
                        }
						
					} else {
                        Answers.logCustomEventWithName("Authentication Error", customAttributes:["Code":error!])
                    }
                })
            }
        }
    
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }

    override func viewDidAppear(animated: Bool) {
        if (currentSession != nil) {
            if (currentSession!.isValid()) {
                performSegueWithIdentifier("segueOne", sender: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



}

