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
    
    @IBOutlet weak var buttonHeight: NSLayoutConstraint!
    @IBOutlet weak var LogInLabel: UILabel!
    @IBOutlet weak var activityRunning: UIActivityIndicatorView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var findPartyButton: UIButton!
    
    //MARK: SPTAuthView Delegate
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {

        setSession(session)
        performSegueWithIdentifier("start_Party", sender: nil)
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {

    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
		Answers.logCustomEventWithName("Authentication Fail", customAttributes:["Type":"Initial"])
    }
    
    
    //MARK: GUI Actions
    
    @IBAction func loginWithSpotify(sender: AnyObject) {
        
        authController.setParameters(spotifyAuthenticator)
        
        let session = sessionHandler.getSession()
        
        if (session != nil) {
            if (session!.isValid()) {
                setSession(session!)
                self.performSegueWithIdentifier("start_Party", sender: nil)
            } else {
                self.LogInLabel.hidden = false
                self.loginButton.hidden = true
                self.findPartyButton.hidden = true
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
                            self.findPartyButton.hidden = false
                            self.performSegueWithIdentifier("start_Party", sender: nil)
                        }
                        
                    } else {
                        Answers.logCustomEventWithName("Authentication Error", customAttributes:["Type":"Renew"])
                    }
                })
            }
        }
        else{
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
    
    func setSession(session: SPTSession) {
        currentSession = session
    }


    //MARK: Default Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginButton.layer.cornerRadius = 15
        self.findPartyButton.layer.cornerRadius = 15
        self.buttonHeight.constant = (self.view.bounds.size.height * 0.25)
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

