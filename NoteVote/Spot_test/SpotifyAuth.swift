//
//  SpotifyAuthController.swift
//  
//  This class handles the app authentication parameters.
//
//  Created by Aaron Kaplan on 9/29/15.
//  Copyright © 2015 NoteVote. All rights reserved.
//

import Foundation

class SpotifyAuth {
    
    private let kClientID = "ddf55f7bf8ec47e1a9a998c53207adb2"
    private let kCallbackURL = "notevote-login://callback"
	private let kTokenSwapURL = "https://quiet-fortress-78046.herokuapp.com/swap"
	private let kTokenRefreshURL = "https://quiet-fortress-78046.herokuapp.com/refresh"
	
	func setParameters(auth: SPTAuth){
        auth.clientID = kClientID
        auth.requestedScopes = [SPTAuthUserReadPrivateScope, SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope]
        auth.redirectURL = NSURL(string: kCallbackURL)
        auth.tokenSwapURL = NSURL(string: kTokenSwapURL)
        auth.tokenRefreshURL = NSURL(string: kTokenRefreshURL)
    }
	
	
    func getClientID() -> String {
        return kClientID
    }
}