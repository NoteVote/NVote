//
//  ViewController.swift
//  
//  This class is a view controller for the login screen and handles user login.
//
//  Created by Aaron Kaplan on 9/22/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SPTAuthViewDelegate {

    // _____ Declarations _____
    
    private let sessionHandler = SessionHandler()
    private let authController = SpotifyAuth()
    private let spotifyAuthenticator = SPTAuth.defaultInstance()
    private var currentSession: SPTSession? = nil
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var registerLabel: UILabel!
    
    
    // _____ SPTAuthViewDelegate Methods _____
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
        print("Login Successful")
        setSession(session)
        performSegueWithIdentifier("segueOne", sender: nil)
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        print("login cancelled")
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
        print("login failed")
    }
    
    
    // _____ GUI Actions _____
    
    @IBAction func loginWithSpotify(sender: AnyObject) {
        
        authController.setParameters(spotifyAuthenticator)
        
        let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
        spotifyAuthenticationViewController.delegate = self
        spotifyAuthenticationViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        spotifyAuthenticationViewController.definesPresentationContext = true
        presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)
    }

    @IBAction func registerButtonPressed(sender: UIButton) {
        //hyperlink to spotify register page and open in safari
        print("register pressed")
        UIApplication.sharedApplication().openURL(NSURL(string: "http://www.spotify.com")!)
    }
    
    
    // _____ Additional Methods _____
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueOne"){
            sessionHandler.storeSession(currentSession!)
        }
    }
    
    func setSession(session: SPTSession) {
        currentSession = session
    }


    // _____ Default View Controller Methods _____
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let session = sessionHandler.getSession()
        
        if (session != nil) {
            if (session!.isValid()) {
                setSession(session!)
            } else {
                print("reauthorize")
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

