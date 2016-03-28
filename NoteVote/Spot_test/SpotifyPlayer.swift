//
//  SpotifyPlayer.swift
//
//  Created by Aaron Kaplan on 1/30/16.
//  Copyright © 2016 NoteVote. All rights reserved.
//

import Foundation
import Parse
import Crashlytics

class SpotifyPlayer: NSObject, SPTAudioStreamingPlaybackDelegate {
	
	var albumArt:UIImage?
	var trackTitle:String?
	var trackArtist:String?
	var currentURI:String?
	
	var musicOptions:[Song] = []
	var searchList:[SPTPartialTrack] = []
	var playlistMusic:[String] = []
	var player:SPTAudioStreamingController?
	private let authController = SpotifyAuth()
	private let spotifyAuthenticator = SPTAuth.defaultInstance()
	
	//MARK: Player Methods
	
	func playUsingSession(sessionObj:SPTSession!){
		
		let kClientID = authController.getClientID()
		
		if player == nil {
			player = SPTAudioStreamingController(clientId: kClientID)
			player?.playbackDelegate = self
		}
		
		if ((player?.loggedIn) == false) {
			player?.loginWithSession(sessionObj, callback: { (error:NSError!) -> Void in
				if error != nil {
					Answers.logCustomEventWithName("Player Error", customAttributes:["Code":error!])
					return
				}
				
				serverLink.syncGetQueue()
				PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"host"], block: nil)
				var currentTrack:String = ""
				if !serverLink.musicList.isEmpty {
					currentTrack = self.pop()
					
					if(currentTrack != ""){
						self.player?.playURI(NSURL(string: currentTrack), callback: { (error:NSError!) -> Void in
							if error != nil {
								Answers.logCustomEventWithName("Player Error", customAttributes:["Code":error!])
								return
							}
							print("play on login... musicList")

						})
					}
					
				} else {
					if(!self.playlistMusic.isEmpty){
						let temp = self.playlistMusic.removeFirst()
						self.playlistMusic.append(temp)
						searchHandler.getURIwithPartial(temp, completion: {(result: String) in
							currentTrack = result
							
							self.player?.playURI(NSURL(string: currentTrack), callback: { (error:NSError!) -> Void in
								if error != nil {
									Answers.logCustomEventWithName("Player Error", customAttributes:["Code":error!])
									return
								}
							})
						})
					}
				}
			})
		}
	}
	
	//MARK: AudioStreaming Delegate
	
	//fires whenever the track changes. on song change, this method fires 3 times. first time, trackMetadata is nil, 2nd time is is the last song played, and 3rd time
	//it is the new song.
	func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
		if (trackMetadata == nil){
			
			serverLink.syncGetQueue()
			PFAnalytics.trackEventInBackground("getqueue", dimensions: ["where":"host"], block: nil)
			
			var currentTrack = ""
			if (!serverLink.musicList.isEmpty) {
				currentTrack = self.pop()
				
				//return if session needs to be renewed
				if (!validateSession(currentTrack)) { return }
				
				if (currentTrack != "") {
					self.player?.playURI(NSURL(string: currentTrack), callback: { (error:NSError!) -> Void in
						if error != nil {
							Answers.logCustomEventWithName("Player Error", customAttributes:["Code":error!])
							return
						}
					})
				}
				
			} else {
				let temp = self.playlistMusic.removeFirst()
				self.playlistMusic.append(temp)
				searchHandler.getURIwithPartial(temp, completion: {(result: String) in
					currentTrack = result
					
					//return if session needs to be renewed
					if (!self.validateSession(currentTrack)) { return }
					
					if (currentTrack != "") {
						self.player?.playURI(NSURL(string: currentTrack), callback: { (error:NSError!) -> Void in
							if error != nil {
								Answers.logCustomEventWithName("Player Error", customAttributes:["Code":error!])
								return
							}
						})
					}
				})
			}
			
			
			
		} else {
			let albumURI = trackMetadata["SPTAudioStreamingMetadataAlbumURI"] as! String
			trackTitle = trackMetadata["SPTAudioStreamingMetadataTrackName"] as? String
			trackArtist = trackMetadata["SPTAudioStreamingMetadataArtistName"] as? String
			currentURI = trackMetadata["SPTAudioStreamingMetadataTrackURI"] as? String

			SPTAlbum.albumWithURI(NSURL(string: albumURI), accessToken: nil, market: "US") { (error:NSError!, albumObj:AnyObject!) -> Void in
                
				let album = albumObj as! SPTAlbum
				
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
							self.albumArt = coverImage
							let notifier = NSNotificationCenter.defaultCenter()
							notifier.postNotificationName("ArtNotification", object: nil, userInfo: nil)

						})
					})
				}
			}
			//Notify data change
			let defaultCenter = NSNotificationCenter.defaultCenter()
			defaultCenter.postNotificationName("MetadataChangeNotification", object: nil, userInfo: nil)
			
		}
	}
	
	//MARK: External Methods
	
	/**
	* Function: pop
	*
	* Parameters:
	*	- None
	*
	* Return: String representing the song's Spotify URI
	*
	* Description:
	*	Gets and removes the top song off of musicList, which should be the highest voted song,
	*	then returns the song's URI.
	*/
	func pop()->String{
		let uri:String = serverLink.musicList[0].objectForKey("uri") as! String
		
		//log song name and vote count
		Answers.logCustomEventWithName("Song Popped", customAttributes: ["Title":serverLink.musicList[0].objectForKey("trackTitle") as! String, "Votes":serverLink.musicList[0].objectForKey("votes") as! Int])
		
		serverLink.removeSong(uri)
		serverLink.musicList.removeAtIndex(0)
        
        //Call clean.
        serverLink.songClean()
        print(serverLink.songCleanup)
        
		PFAnalytics.trackEventInBackground("savequeue", dimensions: ["where":"host"], block: nil)
		return uri
	}


	/**
	* Function: setMusicOptions
	*
	* Parameters:
	*	- None
	*
	* Return: None
	*
	* Description:
	*	Changes songs from Spotify objects into Song objects.
	*	saves all the Song objects in serverLink.musicOptions.
	*/
	func setMusicOptions(){
		self.musicOptions = []
		for track in self.searchList {
			let song:Song = Song()
			song.setURI(String(track.uri))
			song.setTitle(track.name)
			let str = String(track.artists.first)
			
			//Building artist name with parsing.
			let strList = str.componentsSeparatedByString(" ")
			var artistName:String = strList[2]
			if(strList.count-1 > 3){
				for i in 3...strList.count-2{
					artistName += " " + strList[i]
				}
			}
			song.setArtist(artistName)
			self.musicOptions.append(song)
		}
	}
	
	/**
	* Function: playlistToTracks
	*
	* Parameters:
	*	- index: An integer representing the position of a playlist from searchHandler.playlistData
	*
	* Return: None
	*
	* Description:
	*	Takes a specified playlist from searchHandler.playlistData, and pulls the first 100 partial tracks
	*	from Spotify. Converts all tracks from partials to fulls and saves them in playlistMusic. Shuffles
	*	playlistMusic afterwards.
	*/
	func playlistToTracks(index: Int){
		
		//get the selected playlist URI from the list
		let uri:NSURL = searchHandler.playlistData[index].1
		let sessionHandler = SessionHandler()
		let session = sessionHandler.getSession()
		
		//get playlist using URI
		SPTPlaylistSnapshot.playlistWithURI(uri, session: session, callback: { (error:NSError!, result:AnyObject!) -> Void in
			let snapshot = result as! SPTPlaylistSnapshot
			
			//get first 100 partial tracks from playlist
			var trackListItems = snapshot.firstTrackPage.items
			
			//convert partial tracks to full tracks, and append full track URI to trackListFull
			let count = trackListItems.count
			for _ in 0...count-1 {
				let partialTrack = trackListItems.removeFirst() as! SPTPartialTrack
				self.playlistMusic.append(String(partialTrack.playableUri))
				
			}
			self.shuffleArray(self.playlistMusic)
			
			
		})
	}

	//MARK: Helper Methods
	
	/**
	* Function: shuffleArray
	*
	* Parameters:
	*	- None
	*
	* Return: String representing the song's Spotify URI
	*
	* Description:	
	*	copied method from http://iosdevelopertips.com/swift-code/swift-shuffle-array-type.html
	*	for shuffling arrays
	*/
	func shuffleArray<T>(var array: Array<T>) -> Array<T> {
		for var index = array.count - 1; index > 0; index -= 1 {
			// Random int from 0 to index-1
			let j = Int(arc4random_uniform(UInt32(index-1)))
			
			// Swap two array elements
			swap(&array[index], &array[j])
		}
		return array
	}
	
	func validateSession(track: String) -> Bool {
		let session = SessionHandler().getSession()
		if (session!.isValid()) {
			return true
		} else {
			authController.setPremiumParameters(spotifyAuthenticator)
			
			spotifyAuthenticator.renewSession(session, callback:{
				(error: NSError?, session:SPTSession?) -> Void in
				
				if(error == nil){
					SessionHandler().storeSession(session!)
			
					self.player?.playURI(NSURL(string: track), callback: { (error:NSError!) -> Void in
						if error != nil {
							Answers.logCustomEventWithName("Player Error", customAttributes:["Code":error!])
							return
						}
					})
				}
				else{
					Answers.logCustomEventWithName("Authentication Error", customAttributes:["Code":error!])
				}
			})
			return false
		}
	}
}

	